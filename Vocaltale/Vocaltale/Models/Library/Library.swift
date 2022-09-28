//
//  Library.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation
import SQLKit
import SQLiteKit

enum LibraryState: Int {
    case initializing = 0
    case loading = 1
    case loaded = 2
    case unloaded = 3
    case failed = 255
}

class LibraryEvent: ObservableObject, Equatable {
    let state: LibraryState
    let library: Library?
    let error: Error?

    init(state: LibraryState, library: Library? = nil, error: Error? = nil) {
        self.state = state
        self.library = library
        self.error = error
    }

    static func == (lhs: LibraryEvent, rhs: LibraryEvent) -> Bool {
        return lhs.state == rhs.state && lhs.library == rhs.library
            && (lhs.error != nil) == (rhs.error != nil)
    }
}

struct LibraryInfo: Equatable, Codable {
    let version: String
    let uuid: String
}

struct Library: Equatable {
    let info: LibraryInfo
    let mediaConnection: SQLiteConnection
    let mediaDatabase: SQLDatabase
    let url: URL

    static func == (lhs: Library, rhs: Library) -> Bool {
        return lhs.info == rhs.info && lhs.url == rhs.url
    }
}
