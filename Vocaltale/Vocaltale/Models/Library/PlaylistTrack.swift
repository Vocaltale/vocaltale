//
//  PlaylistTrack.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import Foundation

struct PlaylistTrack: Codable, Equatable, Identifiable, Hashable {
    let uuid: String
    let playlistID: String
    let trackID: String
    let order: Int

    var id: String {
        return uuid
    }
}
