//
//  FileError.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/2.
//

import Foundation

enum FileErrorTypes {
    case notSupported
    case sourceFileNotFound
    case sameFileExists
    case libraryCorrupted
}

class FileError: LocalizedError {
    public var errorDescription: String? {
        let message: String
        switch type {
        case .notSupported:
            message = "error_file_not_supported"

        case .sourceFileNotFound:
            message = "error_file_source_not_found"

        case .sameFileExists:
            message = "error_file_same_file_exists"

        case .libraryCorrupted:
            message = "error_file_library_corrupted"
        }

        return NSLocalizedString(message, comment: "")
    }

    let type: FileErrorTypes

    init(type: FileErrorTypes) {
        self.type = type
    }
}
