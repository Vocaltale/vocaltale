//
//  Playlist.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import Foundation

struct Playlist: Codable, Equatable, Identifiable, Hashable {
    let uuid: String
    let name: String
    let order: Int

    var id: String {
        return uuid
    }
}

struct PlaylistItem: Codable, Equatable, Identifiable, Hashable {
    let track: Track
    let playlistTrack: PlaylistTrack?

    var id: String {
        return playlistTrack?.id ?? track.id
    }
}
