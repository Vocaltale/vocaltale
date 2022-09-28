//
//  Artist.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/28.
//

import Foundation

struct Artist: Codable, Equatable, Hashable {
    let uuid: String
    let name: String?

    var displayName: String {
        if let name,
           !name.isEmpty {
            return name
        }

        return NSLocalizedString("artist_unknown", comment: "")
    }

    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.name == rhs.name
    }
}
