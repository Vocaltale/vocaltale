//
//  Track.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/28.
//

import Foundation

struct Track: Codable, Equatable, Identifiable, Hashable {
    let track: Int
    let uuid: String
    let name: String?
    let album: String?
    let albumID: String
    let artist: String?
    let artistID: String
    let filename: String
    let duration: Int
    let disc: Int
    let hash: Int

    var id: String {
        return uuid
    }

    var displayName: String {
        if let name,
           !name.isEmpty {
            return name
        }

        return NSLocalizedString("track_unknown", comment: "")
    }

    var displayAlbum: String {
        if let album,
           !album.isEmpty {
            return album
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

    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.track == rhs.track &&
            lhs.name == rhs.name &&
            lhs.album == rhs.album &&
            lhs.artist == rhs.artist &&
            lhs.filename == rhs.filename &&
            lhs.disc == rhs.disc &&
            lhs.hash == rhs.hash
    }
}
