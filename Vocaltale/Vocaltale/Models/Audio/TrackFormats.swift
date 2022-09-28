//
//  TrackFormats.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/29.
//

import CoreAudio
import Foundation

enum TrackFormatType: Int {
    case unknown = 0
    case pcm = 1
    case dsd = 2
}

protocol TrackFormat {
    var sampleRate: Double { get }
    var sampleSize: Int { get }
    var formatType: TrackFormatType { get }
    var codec: String { get }
}

struct PCMFormat: TrackFormat {
    let sampleRate: Double
    let sampleSize: Int
    let codec: String
    let formatType: TrackFormatType = .pcm

    private init(sampleRate: Double, sampleSize: Int, codec: String) {
        self.sampleRate = sampleRate
        self.sampleSize = sampleSize
        self.codec = codec
    }

    init(sampleRate: Double, sampleSize: Int, formatId: AudioFormatID) {
        let codec: String

        switch formatId {
        case kAudioFormatAppleLossless:
            codec = "Apple Lossless"
        case kAudioFormatFLAC:
            codec = "FLAC"
        case kAudioFormatLinearPCM:
            codec = "Linear PCM"
        default:
            codec = "Linear PCM"
        }

        self.init(sampleRate: sampleRate, sampleSize: sampleSize, codec: codec)
    }
}

struct DSDFormat: TrackFormat {
    let sampleRate: Double
    let sampleSize: Int = 1
    let codec: String
    let formatType: TrackFormatType = .dsd
}
