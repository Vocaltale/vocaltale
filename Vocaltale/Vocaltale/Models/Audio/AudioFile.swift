//
//  AudioFile.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/1/23.
//

import Foundation
import CoreAudio
import AVKit

class AudioFile {
    struct Metadata {
        let duration: CMTime
        let title: String?
        let artist: String?
        let albumTitle: String?
        let track: String?
        let trackTotal: String?
        let disc: String?
        let discTotal: String?
        let artwork: Data?
    }

    let url: URL
    init(url: URL) {
        self.url = url
    }

    func loadMetadata() async -> Metadata? {
        let asset = AVURLAsset(url: url)

        let duration = try? await asset.load(.duration)

        var fileID: AudioFileID?
        var status: OSStatus = AudioFileOpenURL(url as CFURL, .readPermission, 0, &fileID)

        guard status == noErr else { return nil }

        // property info
        var dict: CFDictionary?
        var dictSize = UInt32(MemoryLayout<CFDictionary?>.size(ofValue: dict))
        var artworkData: CFData?
        var artworkSize = UInt32(MemoryLayout<CFDictionary?>.size(ofValue: dict))
        var artwork: Data?

        guard let audioFile = fileID else { return nil }

        status = AudioFileGetProperty(audioFile, kAudioFilePropertyInfoDictionary, &dictSize, &dict)
        guard status == noErr else { return nil }

        status = AudioFileGetProperty(audioFile, kAudioFilePropertyAlbumArtwork, &artworkSize, &artworkData)
        guard status == noErr || status == kAudioFileUnsupportedPropertyError
        else {
            return nil
        }

        AudioFileClose(audioFile)

        guard let dict else { return nil }

        let nsDict = NSDictionary.init(dictionary: dict)
        guard let info = nsDict as? [String: Any]
        else {
            return nil
        }

        debugPrint(info)
        if let artworkData,
           let pointer = CFDataGetBytePtr(artworkData) {
            let size = CFDataGetLength(artworkData)
            let data = Data(bytes: pointer, count: size)

            artwork = data
        }

        if let metadata = try? await asset.load(.metadata) {
            for item in metadata {
                if let commonKey = item.commonKey,
                   commonKey == .commonKeyArtwork,
                   let data = try? await item.load(.dataValue) {
                    artwork = data
                }
            }
        }

        guard let duration
        else {
            return nil
        }

        return Metadata(
            duration: duration,
            title: info["title"] as? String,
            artist: info["artist"] as? String,
            albumTitle: info["album"] as? String,
            track: info["track number"] as? String,
            trackTotal: info["track total"] as? String,
            disc: info["disc number"] as? String,
            discTotal: info["disc total"] as? String,
            artwork: artwork
        )
    }
}
