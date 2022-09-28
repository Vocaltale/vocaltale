//
//  SystemError.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation

class SystemError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(message, comment: "")
    }

    let message: String
    let code: Int

    init(message: String, code: Int) {
        self.message = message
        self.code = code
    }
}
