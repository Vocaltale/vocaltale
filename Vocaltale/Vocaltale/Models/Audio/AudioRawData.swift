//
//  AudioFile.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/2.
//

import Foundation

struct AudioRawData {
    var album: Album
    var artist: Artist
    var track: Track
    let url: URL
    let artwork: Data?

    var trackNumber: Int {
        track.track
    }
}
