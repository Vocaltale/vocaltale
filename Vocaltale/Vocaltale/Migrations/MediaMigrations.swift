//
//  MediaMigrations.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation
import SQLKit

protocol MediaMigrations {
    static var version: String { get }
    static func up(db: SQLDatabase) throws
    static func down(db: SQLDatabase) throws
}
