//
//  FileService.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/2.
//

import AVKit
import CoreAudio
import Foundation
import UniformTypeIdentifiers

class FileService {
    static let instance = FileService()

    func process(file url: URL) async throws -> AudioRawData {
        guard let type = UTType.init(filenameExtension: url.pathExtension),
              type.conforms(to: .audio)
        else {
            throw FileError(type: .notSupported)
        }

        let audioFile = AudioFile(url: url)
        guard let metadata = await audioFile.loadMetadata()
        else {
            throw FileError(type: .notSupported)
        }

        var title: String?
        if let value = metadata.title {
            title = value
        }

        var album: String?
        if let value = metadata.albumTitle {
            album = value
        }

        var track = 1
        if let value = metadata.track {
            if let integer = Int(value) {
                track = integer
            }

            if let string = value.components(separatedBy: "/").first,
               let integer = Int(string) {
                track = integer
            }
        }

        var disc = 1
        if let value = metadata.disc,
           let integer = Int(value) {
            disc = integer
        }

        var artist: String?
        if let value = metadata.artist {
            artist = value
        }

        var artwork: Data?
        if let value = metadata.artwork {
            artwork = value
        }

        let duration = Int(ceil(CMTimeGetSeconds(metadata.duration)))

        var discCount: Int = 1
        if let value = metadata.discTotal,
           let integer = Int(value) {
            discCount = integer
        }

        let resultAlbum = Album(
            uuid: UUID().uuidString,
            name: album,
            artist: artist,
            artistID: "",
            discCount: discCount,
            order: -1
        )

        let sha256 = try url.hash()
        let trackID = UUID().uuidString
        let filename = "\(track)-\(url.lastPathComponent)"

        let resultTrack = Track(
            track: track,
            uuid: trackID,
            name: title,
            album: album,
            albumID: "",
            artist: artist,
            artistID: "",
            filename: filename,
            duration: duration,
            disc: disc,
            hash: sha256
        )
        let resultArtist = Artist(uuid: UUID().uuidString, name: artist)

        return AudioRawData(
            album: resultAlbum,
            artist: resultArtist,
            track: resultTrack,
            url: url,
            artwork: artwork
        )
    }

    func artwork(for album: Album) -> Data? {
        if let libraryURL = LibraryRepository.instance.currentLibraryURL {
            let path = libraryURL.appending(path: "metadata")
                .appending(path: album.uuid)
                .appending(path: "artwork")

            return FileManager.default.contents(atPath: path.relativeString)
        }

        return nil
    }
}
