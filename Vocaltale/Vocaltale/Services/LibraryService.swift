//
//  LibraryService.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation
import SwiftUI
import NIO
import SQLKit
import SQLiteKit
import UniformTypeIdentifiers
import CoreAudio
import AVKit

class LibraryService {
    let documentsPath: [URL]

    private let libraryThreadPool = NIOThreadPool(numberOfThreads: 4)
    private var eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)

    private let serviceThreadPool = NIOThreadPool(numberOfThreads: 4)
    private var serviceEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)

    private let libraryServiceQueue = DispatchQueue(label: "libraryService", attributes: .concurrent)
    private let libraryServiceLock = DispatchSemaphore(value: 8)

    private var query: NSMetadataQuery?
    private var opening: URL?

    static let instance = LibraryService()

    private init() {
        documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    }

#if os(OSX)
    func openLibrary() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canDownloadUbiquitousContents = true
        panel.allowedContentTypes = [ kDefaultProjectUTType ]

        let response = panel.runModal()

        if response == .OK,
           let url = panel.url {

            openLibrary(from: url)
        }
    }

    func createLibrary() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [ kDefaultProjectUTType ]

        let response = panel.runModal()

        if response == .OK,
           let url = panel.url {
            // ignore error for best-effort existing package cleanup
            do {
                try FileManager.default.removeItem(at: url)
            } catch {}

            do {
                try FileManager.default.createDirectory(
                    at: url.appendingPathComponent("data"),
                    withIntermediateDirectories: true
                )
                try FileManager.default.createDirectory(
                    at: url.appendingPathComponent("metadata"),
                    withIntermediateDirectories: true
                )
                FileManager.default.createFile(
                    atPath: url.appendingPathComponent("media.database", conformingTo: .database).relativeString,
                    contents: nil
                )

                openLibrary(from: url)
            } catch {}
        }
    }
#endif

    func importFiles(from url: URL) {
        libraryServiceQueue.async {
            let libraryRepository = LibraryRepository.instance
            let state = libraryRepository.state
            if let isDirectory = url.isDirectory,
               !isDirectory {

                self.libraryServiceLock.wait()
                libraryRepository.incrementFileCount()
                libraryRepository.state = .loading
                Task {
                    do {
                        let audioFile = try await FileService.instance.process(file: url)

                        libraryRepository.copy(file: audioFile) {
                            self.onFileProcessed(state)
                        }
                    } catch {
                        self.onFileProcessed(state)
                    }
                }
            } else if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [
                .isRegularFileKey
            ], options: [
                .skipsHiddenFiles,
                .skipsPackageDescendants
            ]) {
                for case let fileURL as URL in enumerator {
                    if UTType(filenameExtension: fileURL.pathExtension, conformingTo: .audio) != nil {

                        self.libraryServiceLock.wait()
                        libraryRepository.incrementFileCount()
                        libraryRepository.state = .loading
                        Task {
                            do {
                                let audioFile = try await FileService.instance.process(file: fileURL)

                                libraryRepository.copy(file: audioFile) {
                                    self.onFileProcessed(state)
                                }
                            } catch {
                                self.onFileProcessed(state)
                            }
                        }
                    }
                }
            }
        }
    }

    func delete(album: Album) {
        LibraryRepository.instance.delete(album: album)
    }

    func search(for keyword: String) {
        let repository = LibraryRepository.instance
        if keyword.isEmpty {
            repository.searchResults = [:]
            return
        }

        repository.search(for: keyword)
    }

    func openLibrary(from url: URL) {
        if !(doOpenLibrary(from: url) || startDownload(of: url)) {
            initLibrary(at: url)
        }
    }

    @objc func gathered(notification: Notification?) {
        let query = notification?.object as? NSMetadataQuery
        let libraryRepository = LibraryRepository.instance

        query?.enumerateResults { (item: Any, _: Int, _: UnsafeMutablePointer<ObjCBool>) in
            let metadataItem = item as? NSMetadataItem
            let path = metadataItem?.value(forAttribute: NSMetadataItemPathKey) as? String

            if let path,
               let metadataItem,
               let opening,
               path.hasSuffix(opening.cleanFilename) {
                let isDownloaded = isMetadataItemDownloaded(item: metadataItem)

                if isDownloaded {
                    libraryRepository.isDownloading = false

                    _ = doOpenLibrary(from: opening)
                } else if let percentage = metadataItem.value(
                    forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey
                ) as? Double {
                    libraryRepository.downloadProgress = percentage / 100.0
                }
            }
        }
    }
}

// Private functions
extension LibraryService {
    private func initLibrary(at url: URL) {
        do {
            try FileManager.default.createDirectory(
                at: url.appendingPathComponent("data"),
                withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: url.appendingPathComponent("metadata"),
                withIntermediateDirectories: true
            )
            FileManager.default.createFile(
                atPath: url.appendingPathComponent("media.database", conformingTo: .database).relativeString,
                contents: nil
            )

            _ = doOpenLibrary(from: url)
        } catch {}
    }

    private func startDownload(of url: URL) -> Bool {
        let libraryRepository = LibraryRepository.instance

        libraryRepository.isDownloading = true
        libraryRepository.downloadProgress = 0.0

        opening = url

        startMetadataQuery(for: url)

#if os(OSX)
        WindowRepository.instance.isShowingProgressModal = true
#endif

        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: url.iCloud)

            return true
        } catch {}

        return false
    }

    private func startMetadataQuery(for url: URL) {
        if let old = query {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidUpdate,
                object: old
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                object: old
            )

            old.stop()

            self.query = nil
        }

        let query = NSMetadataQuery()
        let filename = url.cleanFilename

        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K ENDSWITH %@", NSMetadataItemPathKey, filename)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(gathered),
            name: NSNotification.Name.NSMetadataQueryDidUpdate,
            object: query
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(gathered),
            name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
            object: query
        )

        query.start()

        self.query = query
    }

    private func isMetadataItemDownloaded(item: NSMetadataItem) -> Bool {
        if item.value(
            forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey
        ) as? String == NSMetadataUbiquitousItemDownloadingStatusCurrent {
            return true
        } else {
            return false
        }
    }

    private func doOpenLibrary(from url: URL) -> Bool {
        if let old = query {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidUpdate,
                object: old
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                object: old
            )

            old.stop()

            self.query = nil
        }

        let mediaConnection: SQLiteConnection
        let mediaDatabase: SQLDatabase

        debugPrint(#function, url)
        try? LibraryRepository.instance.event.library?.mediaConnection.close().wait()

        do {
            let mediaDatabasePath = url.appendingPathComponent("media.database", conformingTo: .database)

            mediaConnection = try SQLiteConnectionSource(
                configuration: SQLiteConfiguration(
                    storage: .file(path: mediaDatabasePath.relativeString),
                    enableForeignKeys: true
                ),
                threadPool: libraryThreadPool
            )
            .makeConnection(logger: Logger(label: "SQLite"), on: eventLoopGroup.any())
            .wait()

            mediaDatabase = mediaConnection.sql()
        } catch {
            return false
        }

        LibraryRepository.instance.event = LibraryEvent(state: .loading)

        try? MediaMigrations1.up(db: mediaDatabase)
        try? MediaMigrations2.up(db: mediaDatabase)

        let info = prepareLibraryInfo(
            for: url,
            version: MediaMigrations1.version,
            uuid: UUID().uuidString
        )

        let library = Library(
            info: info,
            mediaConnection: mediaConnection,
            mediaDatabase: mediaDatabase,
            url: url
        )

        LibraryRepository.instance.currentLibraryURL = url
        libraryServiceQueue.async {
            LibraryRepository.instance.reload(library)
            AudioPlaybackRepository.instance.reload()
        }

        return true
    }

    private func onFileProcessed(_ state: LibraryState) {
        let libraryRepository = LibraryRepository.instance
        libraryRepository.decrementFileCount()
        self.libraryServiceLock.signal()

        if libraryRepository.fileCount == 0 {
            libraryRepository.state = state
            DispatchQueue.main.async {
                libraryRepository.processedFileCount = 0
            }
        }
    }
    private func prepareLibraryInfo(for libraryURL: URL, version: String, uuid: String) -> LibraryInfo {
        let jsonURL = libraryURL.appending(path: "info.json")

        do {
            let data = try Data(contentsOf: jsonURL)
            let info = try JSONDecoder().decode(LibraryInfo.self, from: data)

            return info
        } catch {
            let info = LibraryInfo(version: version, uuid: uuid)

            if let data = try? JSONEncoder().encode(info) {
                try? data.write(to: jsonURL, options: [
                    .atomic
                ])
            }

            return info
        }
    }
}
