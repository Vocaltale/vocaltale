//
//  Album.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/28.
//

import Foundation
import CoreTransferable

struct Album: Codable, Equatable, Identifiable, Hashable {
    let uuid: String
    let name: String?
    let artist: String?
    let artistID: String
    let discCount: Int
    var order: Int

    var id: String {
        return uuid
    }

    var displayName: String {
        if let name,
           !name.isEmpty {
            return name
        }

        return NSLocalizedString("album_unknown", comment: "")
    }

    var displayArtist: String {
        if let artist,
           !artist.isEmpty {
            return artist
        }

        return NSLocalizedString("artist_unknown", comment: "")
    }

    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.name == rhs.name
    }
}
