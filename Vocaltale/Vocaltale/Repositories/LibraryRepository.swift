//
//  LibraryRepository.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation

import SQLKit

class LibraryRepository: ObservableObject {
    enum SearchResultType {
        case albums
        case artists
        case tracks
    }
    static let instance = LibraryRepository()

    private let userDefaults: UserDefaults?

    @Published var event: LibraryEvent
    @Published var currentPlaylistID: String?
    @Published var currentAlbumID: String?
    @Published var currentTrackID: String?
    @Published var tracks = [Track]()
    @Published var albums = [Album]()
    @Published var artists = [Artist]()
    @Published var playlists = [Playlist]()
    @Published var playlistTracks = [PlaylistTrack]()
    @Published var searchResults: [SearchResultType: [AnyHashable]] = [:]
    @Published var keyword: String = ""
    @Published var fileCount = 0
    @Published var processedFileCount = 0
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0

    private let transactionQueue = DispatchQueue(label: "transaction", attributes: .concurrent)
    private let transactionLock = DispatchSemaphore(value: 1)
    private let fileCountLock = DispatchSemaphore(value: 1)
    private let mainLock = DispatchSemaphore(value: 1)

    private init() {
        event = LibraryEvent(state: .initializing)

        do {
            guard let bundleId = Bundle.main.bundleIdentifier,
                  let _userDefaults = UserDefaults(suiteName: "group.\(bundleId)")
            else {
                throw SystemError(
                    message: "userDefaults_initialization_failure",
                    code: kSystemError_UserDefaults_InitializationFailed
                )
            }

            userDefaults = _userDefaults

            event = LibraryEvent(state: .unloaded)
        } catch {
            userDefaults = nil

            event = LibraryEvent(state: .failed, library: nil, error: error)
        }
    }

    var ubiquityContainerURL: URL? {
        let retval = FileManager.default.url(forUbiquityContainerIdentifier: nil) // kDefaultUbiquityContainerID)

        return retval
    }

    var ubiquityPublicDocumentURL: URL? {
        let retval = FileManager.default.url(forUbiquityContainerIdentifier: kDefaultUbiquityContainerID)?
            .appending(path: "Documents", directoryHint: .isDirectory)

        return retval
    }

    var ubiquityCurrentLibraryURL: URL? {
        guard let info = event.library?.info
        else {
            return nil
        }

        let filename = "\(info.uuid)"

        return ubiquityPublicDocumentURL?.appending(path: filename, directoryHint: .isDirectory)
    }

    private var _currentLibraryURL: URL?
    var currentLibraryURL: URL? {
        get {
            if let _currentLibraryURL {
                return _currentLibraryURL
            }

            _currentLibraryURL = userDefaults?.url(forKey: "CURRENT_OPENED_LIBRARY")

            return _currentLibraryURL
        }
        set(url) {
            _currentLibraryURL = url
            userDefaults?.set(url, forKey: "CURRENT_OPENED_LIBRARY")
        }
    }

    var currentAlbum: Album? {
        get {
            albums.first { album in
                album.uuid == currentAlbumID
            }
        }
        set(album) {
            if let id = album?.uuid {
                userDefaults?.set(id, forKey: "CURRENT_OPENED_ALBUM")
            } else {
                userDefaults?.removeObject(forKey: "CURRENT_OPENED_ALBUM")
            }

            currentAlbumID = album?.uuid
        }
    }

    var currentPlaylist: Playlist? {
        get {
            playlists.first { playlist in
                playlist.uuid == currentPlaylistID
            }
        }
        set(playlist) {
            if let id = playlist?.uuid {
                userDefaults?.set(id, forKey: "CURRENT_OPENED_PLAYLIST")
            } else {
                userDefaults?.removeObject(forKey: "CURRENT_OPENED_PLAYLIST")
            }

            currentPlaylistID = playlist?.uuid
        }
    }

    var state: LibraryState {
        get {
            event.state
        }

        set(state) {
            DispatchQueue.main.async {
                self.event = LibraryEvent(state: state, library: self.event.library, error: self.event.error)
            }
        }
    }

    func incrementFileCount() {
        let lock = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            self.fileCountLock.wait()
            self.fileCount += 1
            self.processedFileCount += 1
            self.fileCountLock.signal()
            lock.signal()
        }

        lock.wait()
    }

    func decrementFileCount() {
        let lock = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            self.fileCountLock.wait()
            self.fileCount -= 1
            self.fileCountLock.signal()
            lock.signal()
        }

        lock.wait()
    }

    func reload(_ library: Library) {
        let db = library.mediaDatabase
        let lock = DispatchSemaphore(value: 0)

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()

            Task {
                await MainActor.run {
                    self.currentAlbumID = self.userDefaults?.string(forKey: "CURRENT_OPENED_ALBUM")
                }

                do {
                    let albumResults = try await db.select()
                        .from("albums")
                        .columns("*")
                        .orderBy("order")
                        .all(decoding: Album.self)

                    let trackResults = try await db.select()
                        .from("tracks")
                        .columns("*")
                        .all(decoding: Track.self)

                    let artistResults = try await db.select()
                        .from("artists")
                        .columns("*")
                        .all(decoding: Artist.self)

                    let playlistResults = try await db.select()
                        .from("playlists")
                        .columns("*")
                        .all(decoding: Playlist.self)

                    let playlistTracksResults = try await db.select()
                        .from("playlist_tracks")
                        .columns("*")
                        .all(decoding: PlaylistTrack.self)

                    await MainActor.run {
                        self.albums = albumResults
                        self.tracks = trackResults
                        self.artists = artistResults
                        self.playlists = playlistResults
                        self.playlistTracks = playlistTracksResults

                        self.event = LibraryEvent(state: .loaded, library: library, error: nil)
                    }
                } catch {
                    await MainActor.run {
                        self.event = LibraryEvent(state: .failed, library: nil, error: error)
                    }
                }

                await MainActor.run {
                    self.currentAlbumID = self.userDefaults?.string(forKey: "CURRENT_OPENED_ALBUM")
                    self.currentPlaylistID = self.userDefaults?.string(forKey: "CURRENT_OPENED_PLAYLIST")

#if os(iOS)
                    if let currentPlaylist = self.currentPlaylist {
                        self.currentAlbum = nil
                        WindowRepository.instance.selectedTabTag = .playlist
                        WindowRepository.instance.playlistPath.setPlaylist(currentPlaylist)
                    } else if let currentAlbum = self.currentAlbum {
                        self.currentPlaylist = nil
                        WindowRepository.instance.selectedTabTag = .library
                        WindowRepository.instance.libraryPath.setAlbum(currentAlbum)
                    }
#endif
                }

                self.mainLock.signal()
                self.transactionLock.signal()
                lock.signal()
            }
        }

        lock.wait()
    }

    func reload() {
        guard let library = event.library
        else {
            return
        }

        let db = library.mediaDatabase

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()

            Task {
                do {
                    let albumResults = try await db.select()
                        .from("albums")
                        .columns("*")
                        .orderBy("order")
                        .all(decoding: Album.self)

                    let trackResults = try await db.select()
                        .from("tracks")
                        .columns("*")
                        .all(decoding: Track.self)

                    let artistResults = try await db.select()
                        .from("artists")
                        .columns("*")
                        .all(decoding: Artist.self)

                    let playlistResults = try await db.select()
                        .from("playlists")
                        .columns("*")
                        .all(decoding: Playlist.self)

                    let playlistTracksResults = try await db.select()
                        .from("playlist_tracks")
                        .columns("*")
                        .all(decoding: PlaylistTrack.self)

                    await MainActor.run {
                        self.albums = albumResults
                        self.tracks = trackResults
                        self.artists = artistResults
                        self.playlists = playlistResults
                        self.playlistTracks = playlistTracksResults

                        self.event = LibraryEvent(state: .loaded, library: library, error: nil)
                    }
                } catch {
                }

                self.mainLock.signal()
                self.transactionLock.signal()
            }
        }
    }

    func playlist(of playlistID: String) -> Playlist? {
        let retval = playlists.first { p in
            p.id == playlistID
        }

        return retval
    }

    func tracks(for playlist: Playlist) -> [PlaylistTrack] {
        playlistTracks.filter { track in
            track.playlistID == playlist.id
        }
    }

    func track(of trackID: String) -> Track? {
        let retval = tracks.first { t in
            t.id == trackID
        }

        return retval
    }

    func tracks(for album: Album) -> [Track] {
        let retval = tracks.filter { t in
            t.albumID == album.id
        }.sorted { a, b in
            if b.disc == a.disc {
                return b.track >= a.track
            }

            return b.disc > a.disc
        }

        return retval
    }

    func album(of albumID: String) -> Album? {
        let retval = albums.first { t in
            t.id == albumID
        }

        return retval
    }

    func artist(by uuid: String) -> Artist {
        let retval = artists.first { artist in
            artist.uuid == uuid
        } ?? Artist( uuid: "ffffffff-ffff-ffff-ffff-ffffffffffff", name: NSLocalizedString("artist_unknown", comment: ""))

        return retval
    }

    func artistNames(of album: Album) -> [String] {
        let artists = tracks(for: album).reduce([String: Int]()) { results, track in
            var retval = results

            var count = retval[track.displayArtist] ?? 0

            count += 1

            retval[track.displayArtist] = count

            return retval
        }

        return artists.sorted { a, b in
            if a.value != b.value {
                return a.value > b.value
            }

            return a.key > b.key
        }.map { (key: String, _: Int) in
            key
        }
    }

    func copy(file source: AudioRawData, _ callback: @escaping () -> Void) {
        guard let db = event.library?.mediaDatabase,
              let libraryURL = currentLibraryURL,
              let ubiquityURL = ubiquityCurrentLibraryURL
        else {
            return
        }

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()

            Task {
                var albumUUID: String?
                do {
                    try await db.raw("begin transaction;").run()
                    let artist = try await self.tryAddArtist(db, source.artist)

                    let actualArtist = artist ?? self.artists.first(where: { a in
                        a == source.artist
                    })!

                    let album = try await self.tryAddAlbum(db, source.album, actualArtist)

                    let actualAlbum = album ?? self.albums.first(where: { a in
                        a == source.album
                    })!
                    albumUUID = actualAlbum.uuid

                    let track = try await self.tryAddTrack(db, source.track, actualAlbum, actualArtist)

                    let dataDirectory = libraryURL.appending(path: "data/\(actualAlbum.uuid)/\(source.track.disc)")
                    let destination = dataDirectory.appending(path: "\(source.trackNumber).\(source.url.pathExtension)")
                    let ubiquitousDestination = ubiquityURL
                        .appending(path: "data/\(actualAlbum.uuid)/\(source.track.disc)", directoryHint: .isDirectory)

                    try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
                    try? FileManager.default.copyItem(at: source.url, to: destination)
                    if let result = try? ubiquitousDestination.mkdirp(),
                       result {
                        let ubiquitousFileURL = ubiquitousDestination.appending(path: "\(source.track.filename)")

                        if FileManager.default.isUbiquitousItem(at: destination) {
                            try FileManager.default.moveItem(at: destination, to: ubiquitousFileURL)
                        } else {
                            try FileManager.default.setUbiquitous(
                                true,
                                itemAt: destination,
                                destinationURL: ubiquitousFileURL
                            )
                        }
                    } else {
                        throw FileError(type: .libraryCorrupted)
                    }

                    let metadataDirectory = libraryURL.appending(path: "metadata/\(actualAlbum.uuid)")
                    if let artwork = source.artwork {
                        let artworkPath = metadataDirectory.appending(path: "artwork")

                        try FileManager.default.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
                        FileManager.default.createFile(atPath: artworkPath.relativePath, contents: artwork)
                    }

                    try await db.raw("commit;").run()

                    await MainActor.run {
                        if let album {
                            self.albums.append(album)
                        }

                        if let track {
                            self.tracks.append(track)
                        }

                        if let artist {
                            self.artists.append(artist)
                        }
                    }
                } catch {
                    debugPrint(#function, error)
                    if let albumUUID {
                        let destinationDirectory = libraryURL.appending(path: "data/\(albumUUID)")

                        try? FileManager.default.removeItem(at: destinationDirectory)
                    }

                    try? await db.raw("rollback;").run()
                }

                self.mainLock.signal()
                self.transactionLock.signal()

                callback()
            }
        }
    }

    func delete(
        _ playlistTrack: PlaylistTrack,
        from playlist: Playlist,
        completion: @escaping () -> Void
    ) {
        guard let db = event.library?.mediaDatabase
        else {
            return
        }

        transactionQueue.async {
            self.transactionLock.wait()

            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryDeletePlaylistTrack(db, playlistTrack)

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("???", error)
                    try? await db.raw("rollback;").run()
                }

                self.transactionLock.signal()

                await MainActor.run(body: {
                    completion()
                })
            }
        }
    }

    func delete(album: Album) {
        guard let db = event.library?.mediaDatabase,
              let ubiquityURL = ubiquityCurrentLibraryURL,
              let libraryURL = currentLibraryURL
        else {
            return
        }

        transactionQueue.async {
            self.transactionLock.wait()

            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryDeleteTracks(db, album)
                    try await self.tryDeleteAlbum(db, album)

                    let artistID = try? await self.tryDeleteArtist(db, album)

                    let destinationDirectory = libraryURL.appending(path: "data/\(album.uuid)")
                    let ubiquitousDestination = ubiquityURL
                        .appending(path: "data/\(album.uuid)", directoryHint: .isDirectory)

                    try? FileManager.default.removeItem(at: destinationDirectory)
                    try? FileManager.default.removeItem(at: ubiquitousDestination)

                    await MainActor.run {
                        self.tracks.removeAll { t in
                            t.albumID == album.uuid
                        }

                        self.albums.removeAll { a in
                            a == album
                        }

                        if let artistID {
                            self.artists.removeAll { a in
                                a.uuid == artistID
                            }
                        }
                    }

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("???", error)
                    try? await db.raw("rollback;").run()
                }

                self.transactionLock.signal()
            }
        }
    }

    func search(for keyword: String) {
        self.keyword = keyword
        guard let regex = try? Regex("^.*\(keyword).*$").ignoresCase()
        else {
            return
        }

        let albums = albums.filter { a in
            a.displayName.contains(regex) || a.displayArtist.contains(regex) || artistNames(of: a).contains(where: { string in
                string.contains(regex)
            })
        }

        if albums.count > 0 {
            searchResults[.albums] = albums
        } else {
            searchResults.removeValue(forKey: .albums)
        }

        let artists = artists.filter { a in
            a.displayName.contains(regex)
        }

        if artists.count > 0 {
            searchResults[.artists] = artists
        } else {
            searchResults.removeValue(forKey: .artists)
        }

        let tracks = tracks.filter { a in
            a.displayName.contains(regex) || a.displayArtist.contains(regex) || a.displayAlbum.contains(regex)
        }

        if tracks.count > 0 {
            searchResults[.tracks] = tracks
        } else {
            searchResults.removeValue(forKey: .tracks)
        }
    }

    func reorder(to albums: [Album]) {
        guard let db = event.library?.mediaDatabase
        else {
            return
        }

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()
            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryReorder(db, to: albums)

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("error", error)
                    try? await db.raw("rollback;").run()
                }

                self.mainLock.signal()
                self.transactionLock.signal()
                self.reload()
            }
        }
    }

    func reorder(to playlists: [Playlist]) {
        guard let db = event.library?.mediaDatabase
        else {
            return
        }

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()
            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryReorder(db, to: playlists)

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("error", error)
                    try? await db.raw("rollback;").run()
                }

                self.mainLock.signal()
                self.transactionLock.signal()
                self.reload()
            }
        }
    }

    func reorder(to tracks: [PlaylistTrack]) {
        guard let db = event.library?.mediaDatabase
        else {
            return
        }

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()
            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryReorder(db, to: tracks)

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("error", error)
                    try? await db.raw("rollback;").run()
                }

                self.mainLock.signal()
                self.transactionLock.signal()
                self.reload()
            }
        }
    }
}

// MARK: Playlist operations
extension LibraryRepository {
    func createPlaylist(_ name: String) {
        guard let db = event.library?.mediaDatabase
        else {
            return
        }

        let playlist = Playlist(uuid: UUID().uuidString, name: name, order: playlists.count + 1)

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()
            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryAddPlaylist(db, playlist)

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("error", error)
                    try? await db.raw("rollback;").run()
                }

                self.mainLock.signal()
                self.transactionLock.signal()
                self.reload()
            }
        }
    }

    func add(track: Track, to playlist: Playlist) {
        guard let db = event.library?.mediaDatabase
        else {
            return
        }

        let tracks = tracks(for: playlist)
        let playlistTrack = PlaylistTrack(
            uuid: UUID().uuidString, playlistID: playlist.id, trackID: track.id, order: tracks.count + 1
        )

        transactionQueue.async {
            self.transactionLock.wait()
            self.mainLock.wait()
            Task {
                do {
                    try await db.raw("begin transaction;").run()

                    try await self.tryAddTrackToPlaylist(db, playlistTrack)

                    try await db.raw("commit;").run()
                } catch {
                    debugPrint("error", error)
                    try? await db.raw("rollback;").run()
                }

                self.mainLock.signal()
                self.transactionLock.signal()
                self.reload()
            }
        }
    }
}

extension LibraryRepository {
    private func tryFetchPlaylistTracks(_ db: SQLDatabase, _ playlist: Playlist) throws -> [PlaylistTrack] {
        try db.select()
            .from("playlist_tracks")
            .column("*")
            .where("playlistID", .equal, playlist.uuid)
            .all(decoding: PlaylistTrack.self)
            .wait()
    }

    private func tryAddTrackToPlaylist(_ db: SQLDatabase, _ playlistTrack: PlaylistTrack) async throws {
        try await db.insert(into: "playlist_tracks")
            .model(playlistTrack)
            .run()
    }

    private func tryAddPlaylist(_ db: SQLDatabase, _ playlist: Playlist) async throws {
        if !playlists.contains(playlist) {
            try await db.insert(into: "playlists")
                .model(playlist)
                .run()
        }
    }

    private func tryAddAlbum(_ db: SQLDatabase, _ inputAlbum: Album, _ artist: Artist) async throws -> Album? {
        if !albums.contains(inputAlbum) {
            let order = (albums.last?.order ?? albums.count) + 1
            let album = Album(
                uuid: inputAlbum.uuid,
                name: inputAlbum.name,
                artist: artist.name,
                artistID: artist.uuid,
                discCount: inputAlbum.discCount,
                order: order
            )

            try await db.insert(into: "albums")
                .model(album)
                .run()

            return album
        }

        return nil
    }

    private func tryAddTrack(
        _ db: SQLDatabase,
        _ inputTrack: Track,
        _ album: Album,
        _ artist: Artist
    ) async throws -> Track? {
        if !tracks.contains(inputTrack) {
            let track = Track(
                track: inputTrack.track,
                uuid: inputTrack.uuid,
                name: inputTrack.name,
                album: album.name,
                albumID: album.uuid,
                artist: artist.name,
                artistID: artist.uuid,
                filename: inputTrack.filename,
                duration: inputTrack.duration,
                disc: inputTrack.disc,
                hash: inputTrack.hash
            )

            try await db.insert(into: "tracks")
                .model(track)
                .run()

            return track
        }

        return nil
    }

    private func tryAddArtist(_ db: SQLDatabase, _ artist: Artist) async throws -> Artist? {
        if !artists.contains(artist) {
            try await db.insert(into: "artists")
                .model(artist)
                .run()

            return artist
        }

        return nil
    }

    private func tryDeleteAlbum(_ db: SQLDatabase, _ album: Album) async throws {
        try await db.delete(from: "albums")
            .where("uuid", .equal, album.uuid)
            .run()
    }

    private func tryDeleteTracks(_ db: SQLDatabase, _ album: Album) async throws {
        let tracks = try await db.select()
            .from("tracks")
            .columns("*")
            .where("albumID", .equal, album.id)
            .all(decoding: Track.self)

        var affected: [Playlist] = []
        for track in tracks {
            let playlistTracks = try await db.select()
                .from("playlist_tracks")
                .columns("*")
                .where("trackID", .equal, track.id)
                .all(decoding: PlaylistTrack.self)

            var playlist: [Playlist] = []
            for playlistTrack in playlistTracks {
                let result = try await db.select()
                    .from("playlists")
                    .columns("*")
                    .where("uuid", .equal, playlistTrack.playlistID)
                    .all(decoding: Playlist.self)
                playlist.append(contentsOf: result)
            }
            affected.append(contentsOf: playlists)
        }

        try await db.delete(from: "playlist_tracks")
            .where("trackID", .in, tracks.map({ track in
                track.uuid
            }))
            .run()

        let playlists = Set(affected)
        for playlist in playlists {
            let playlistTracks = try await db.select()
                .from("playlist_tracks")
                .column("*")
                .where("playlistID", .equal, playlist.id)
                .orderBy("order", .ascending)
                .all(decoding: PlaylistTrack.self)
            try await tryReorder(db, to: playlistTracks)
        }

        try await db.delete(from: "tracks")
            .where("albumID", .equal, album.uuid)
            .run()
    }

    private func tryDeletePlaylistTrack(
        _ db: SQLDatabase,
        _ playlistTrack: PlaylistTrack
    ) async throws{
        try await db.delete(from: "playlist_tracks")
            .where("uuid", .equal, playlistTrack.id)
            .run()

        let playlistTracks = try await db.select()
            .from("playlist_tracks")
            .column("*")
            .where("playlistID", .equal, playlistTrack.playlistID)
            .orderBy("order", .ascending)
            .all(decoding: PlaylistTrack.self)
        try await tryReorder(db, to: playlistTracks)
    }

    private func tryDeleteArtist(_ db: SQLDatabase, _ album: Album) async throws -> String? {
        let artistAlbums = try await db.select()
            .columns("*")
            .from("albums")
            .where("artistID", .equal, album.artistID)
            .all()

        if artistAlbums.isEmpty {
            try await db.delete(from: "artists")
                .where("uuid", .equal, album.artistID)
                .run()

            return album.artistID
        }

        return nil
    }

    private func tryReorder(_ db: SQLDatabase, to albums: [Album]) async throws {
        for i in 0..<albums.count {
            let album = albums[i]
            try await db.update("albums")
                .where("uuid", .equal, album.uuid)
                .set("order", to: i + 1)
                .run()
        }
    }

    private func tryReorder(_ db: SQLDatabase, to playlists: [Playlist]) async throws {
        for i in 0..<playlists.count {
            let playlist = playlists[i]
            try await db.update("playlists")
                .where("uuid", .equal, playlist.uuid)
                .set("order", to: i + 1)
                .run()
        }
    }

    private func tryReorder(_ db: SQLDatabase, to tracks: [PlaylistTrack]) async throws {
        for i in 0..<tracks.count {
            let track = tracks[i]
            try await db.update("playlist_tracks")
                .where("uuid", .equal, track.uuid)
                .set("order", to: i + 1)
                .run()
        }
    }
}
