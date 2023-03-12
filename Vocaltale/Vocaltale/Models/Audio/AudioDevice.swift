//
//  AudioDevice.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/9.
//

import AVFoundation
import Foundation

struct OutputAudioDevice: Identifiable, Equatable {
    let audioDeviceID: AudioDeviceID
    let id: String
    let name: String
    let isDefault: Bool
}

struct AudioDevice {
    let audioDeviceID: AudioDeviceID

    var hasOutput: Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: 0
        )

        var propsize = UInt32(MemoryLayout<CFString?>.size)
        var result = AudioObjectGetPropertyDataSize(audioDeviceID, &address, 0, nil, &propsize)
        if result != noErr {
            return false
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propsize))
        result = AudioObjectGetPropertyData(audioDeviceID, &address, 0, nil, &propsize, bufferList)
        if result != noErr {
            return false
        }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        for bufferNum in 0..<buffers.count where buffers[bufferNum].mNumberChannels > 0 {
            return true
        }

        return false
    }

    var uid: String? {
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceUID),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
        )

        var name: CFString?
        var propsize = UInt32(MemoryLayout<CFString?>.size)
        let result = AudioObjectGetPropertyData(audioDeviceID, &address, 0, nil, &propsize, &name)
        if result != noErr {
            return nil
        }

        return name as String?
    }

    var name: String? {
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
        )

        var name: CFString?
        var propsize = UInt32(MemoryLayout<CFString?>.size)
        let result = AudioObjectGetPropertyData(audioDeviceID, &address, 0, nil, &propsize, &name)
        if result != noErr {
            return nil
        }

        return name as String?
    }
}
