//
//  AudioPlayerRepository.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/9.
//

import Foundation
import AVKit
import MediaPlayer
import SwiftUI
import CoreData

class AudioPlaybackRepository: NSObject, ObservableObject {
    static let instance = AudioPlaybackRepository()

    private var isRegisteredForNotifications = false
    private let userDefaults: UserDefaults?
    private var audioPlayer: AVAudioPlayer = AVAudioPlayer()

    @Published var volume: Float = 1.0
    @Published var volumeControllable: Bool = true
    @Published var progress: Double = 0 // for display
    @Published var isPlaying = false
    var currentProgress: Double {
        return audioPlayer.currentTime / max(audioPlayer.duration, 1)
    }

    @Published var currentAlbum: Album?
    @Published var currentTrack: Track?
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false

    private var userDefaultsCurrentTrackID: String? {
        get {
            userDefaults?.string(forKey: "AUDIO_PLAYER_CURRENT_TRACK")
        }
        set(value) {
            userDefaults?.set(value, forKey: "AUDIO_PLAYER_CURRENT_TRACK")
        }
    }

    @Published var currentTrackIndex: Int?
    @Published var isLoop: Bool = true

    private var userDefaultsIsLoop: Bool? {
        get {
            userDefaults?.bool(forKey: "AUDIO_PLAYER_IS_LOOP")
        }
        set(value) {
            userDefaults?.set(value, forKey: "AUDIO_PLAYER_IS_LOOP")
        }
    }

    @Published var isShuffle: Bool = false

    private var userDefaultsIsShuffle: Bool? {
        get {
            userDefaults?.bool(forKey: "AUDIO_PLAYER_IS_SHUFFLE")
        }
        set(value) {
            userDefaults?.set(value, forKey: "AUDIO_PLAYER_IS_SHUFFLE")
        }
    }

    @Published var playlist: [Track]?

    @Published var isUsingDefaultDevice = true

#if os(OSX)
    @Published var defaultDevice: OutputAudioDevice?
    @Published var outputDevices: [OutputAudioDevice] = []

    @Published var currentDevice: OutputAudioDevice?
#endif

    private var query: NSMetadataQuery?
    private var artworkQuery: NSMetadataQuery?
    private var currentURL: URL?
    private var artworkURL: URL?
    private var timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
    private let operationQueue = OperationQueue()
#if os(iOS)
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isObservingPlayback = false
#endif

    override private init() {
        do {
            guard let bundleId = Bundle.main.bundleIdentifier,
                  let userDefaults = UserDefaults(suiteName: "group.\(bundleId)")
            else {
                throw SystemError(
                    message: "userDefaults_initialization_failure",
                    code: kSystemError_UserDefaults_InitializationFailed
                )
            }

            self.userDefaults = userDefaults
        } catch {
            self.userDefaults = nil
        }

        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated

        super.init()

#if os(iOS)
        // a hack to keep jobs running in background by playing zero audio signal
        engine.attach(player)
        engine.connect(
            player,
            to: engine.mainMixerNode,
            format: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000.0, channels: 2, interleaved: false)
        )
        engine.prepare()
#endif

        timer.setEventHandler { [weak self] in
            self?.updatePlaybackStatus()
        }
        timer.schedule(wallDeadline: .now(), repeating: .milliseconds(500))
        timer.activate()
        timer.suspend()

#if os(OSX)
        getAudioDevices()
        getDefaultDevice { device in
            if let device,
               self.isUsingDefaultDevice {
                self.currentDevice = device
            }
        }
        registerForNotifications()
        observeSystemVolume()
#endif
    }

    deinit {
        timer.cancel()
#if os(OSX)
        unregisterForNotifications()
        unregisterSystemVolumeObserver()
#endif
    }

    func reload() {
        if let userDefaults {
            initUserDefaults(userDefaults)
        }
    }
}

// MARK: playback controls
extension AudioPlaybackRepository {
    func setLoop(_ value: Bool) {
        userDefaultsIsLoop = value

        isLoop = value
    }

    func setShuffle(_ value: Bool) {
        userDefaultsIsShuffle = value

        isShuffle = value

        playlist = nextPlaylist()

        if let playlist,
           let currentTrack {
            currentTrackIndex = playlist.firstIndex(of: currentTrack)
        }
    }

    func incrementVolume() {
        // almost +1dB
        volume /= 0.9

#if os(OSX)
        setSystemVolume()
#endif
    }

    func decrementVolume() {
        // almost -1dB
        volume *= 0.9

#if os(OSX)
        setSystemVolume()
#endif
    }

    func toggle() {
        if audioPlayer.isPlaying {
            pause()
        } else {
            start()
        }
    }

    func start() {
        if currentTrack != nil && playlist != nil && !isDownloading {
            audioPlayer.play()
            timer.resume()

            isPlaying = true

#if os(OSX)
            MPNowPlayingInfoCenter.default().playbackState = .playing
#endif

            updateUserDefaults()
            return
        }

        if let currentTrack,
           let album = LibraryRepository.instance.album(of: currentTrack.albumID) {
            play(LibraryRepository.instance.tracks(for: album), of: album, from: currentTrack)
        } else if let album = LibraryRepository.instance.currentAlbum {
            play(album: album)
        }
    }

    func pause() {
        guard !isDownloading else { return }

        audioPlayer.pause()
        timer.suspend()
        isPlaying = false

#if os(OSX)
        MPNowPlayingInfoCenter.default().playbackState = .paused
#endif
    }

    func seek(_ progress: Double) {
        // HACK: make the player to complete playback for delegate to trigger next()
        let time = min(1.0, progress) * audioPlayer.duration

        audioPlayer.currentTime = time
        if time >= audioPlayer.duration {
            next()
        }
    }

    func play(album: Album) {
        let tracks = LibraryRepository.instance.tracks(for: album)

        if isShuffle {
            playlist = tracks.shuffled()
        } else {
            playlist = tracks
        }

        guard let track = playlist?.first
        else {
            playlist = nil
            return
        }

        guard let audio = ubiquityURL(for: track, under: album)
        else {
            return
        }

        currentAlbum = album
        currentTrack = track
        currentTrackIndex = 0

        beginPlayback(of: audio)
    }

    func play(_ track: Track) {
        guard let album = LibraryRepository.instance.album(of: track.albumID),
              let audio = ubiquityURL(for: track, under: album)
        else {
            return
        }

        let tracks = LibraryRepository.instance.tracks(for: album)

        if isShuffle {
            playlist = tracks.shuffled()
        } else {
            playlist = tracks
        }

        currentAlbum = album
        currentTrack = track
        currentTrackIndex = playlist?.firstIndex(of: track)

        beginPlayback(of: audio)
    }

    func play(_ tracks: [Track], of album: Album, from track: Track) {
        guard let audio = ubiquityURL(for: track, under: album)
        else {
            return
        }

        if isShuffle {
            playlist = tracks.shuffled()
        } else {
            playlist = tracks
        }

        currentAlbum = album
        currentTrack = track
        currentTrackIndex = playlist?.firstIndex(of: track)

        beginPlayback(of: audio)
    }

    func rewind() {
        let time = audioPlayer.currentTime
        if time <= 1 {
            prev()
        } else {
            audioPlayer.currentTime = 0
        }
    }

    func prev() {
        DispatchQueue.main.sync {
            if let currentTrackIndex,
               let playlist {
                if currentTrackIndex == 0 {
                    self.playlist = nextPlaylist()
                    self.currentTrackIndex = 0

                    currentTrack = self.playlist?.first
                } else {
                    self.currentTrackIndex = currentTrackIndex - 1

                    currentTrack = playlist[currentTrackIndex - 1]
                }
            }
        }
        play()
    }

    func next() {
        var finished = false
        progress = 0.0

        if let currentTrackIndex,
           let playlist {
            if currentTrackIndex == playlist.count - 1 {
                finished = true
                if isLoop {
                    self.playlist = nextPlaylist()
                    self.currentTrackIndex = 0

                    currentTrack = self.playlist?.first
                }
            } else if currentTrackIndex < playlist.count - 1 {
                self.currentTrackIndex = currentTrackIndex + 1

                currentTrack = playlist[currentTrackIndex + 1]
            }
        } else {
            self.playlist = nextPlaylist()
            self.currentTrackIndex = 0

            currentTrack = self.playlist?.first
        }

        if finished && !isLoop {
            pause()
        } else {
            play()
        }
    }
}

extension AudioPlaybackRepository {
#if os(OSX)
    func getAudioDevices() {
        var propsize: UInt32 = 0

        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
        )

        var result = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(MemoryLayout<AudioObjectPropertyAddress>.size),
            nil,
            &propsize
        )

        if result != noErr {
            debugPrint("Error \(result) from AudioObjectGetPropertyDataSize")
            return
        }

        let numDevices = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))

        var deviceIDs = [AudioDeviceID]()
        for _ in 0..<numDevices {
            deviceIDs.append(AudioDeviceID())
        }

        result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propsize,
            &deviceIDs
        )

        if result != noErr {
            debugPrint("Error \(result) from AudioObjectGetPropertyData")
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.outputDevices = deviceIDs.map { deviceID in
                let audioDevice = AudioDevice(audioDeviceID: deviceID)
                if audioDevice.hasOutput {
                    if let name = audioDevice.name,
                       let uid = audioDevice.uid {
                        return OutputAudioDevice(audioDeviceID: deviceID, id: uid, name: name, isDefault: false)
                    }
                }

                return nil
            }.filter { device in
                device != nil
            }.map { device in
                return device!
            }
        }
    }

    func getDefaultDevice(_ completion: ((OutputAudioDevice?) -> Void)? = nil) {
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
        )
        var deviceID = AudioDeviceID()

        var propsize: UInt32 = 0
        var result = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(MemoryLayout<AudioObjectPropertyAddress>.size),
            nil,
            &propsize
        )

        if result != noErr {
            debugPrint("Error \(result) from AudioObjectGetPropertyDataSize")
            return
        }

        result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propsize,
            &deviceID
        )
        if result != noErr {
            debugPrint("Error \(result) from AudioObjectGetPropertyData")
            return
        }

        let audioDevice = AudioDevice(audioDeviceID: deviceID)

        if let name = audioDevice.name,
           let id = audioDevice.uid {
            let device = OutputAudioDevice(
                audioDeviceID: deviceID,
                id: id,
                name: String(format: NSLocalizedString("audio_device_default", comment: ""), name),
                isDefault: true
            )

            DispatchQueue.main.async { [weak self] in
                self?.defaultDevice = device
                if let value = self?.volume(of: device) {
                    self?.volumeControllable = true
                    self?.volume = value
                } else {
                    self?.volumeControllable = false
                    self?.volume = 1.0
                }

                completion?(device)
            }
        } else {
            completion?(nil)
        }
    }
    func syncVolume() {
        if let currentDevice {
            DispatchQueue.main.async { [weak self] in
                if let value = self?.volume(of: currentDevice) {
                    self?.volumeControllable = true
                    self?.volume = value
                } else {
                    self?.volumeControllable = false
                    self?.volume = 1.0
                }
            }
        }
    }

    func setSystemVolume() {
        if let currentDevice,
           volumeControllable {
            var volume = Float32(volume) // 0.0 ... 1.0
            let volumeSize = UInt32(MemoryLayout.size(ofValue: volume))

            var volumePropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain)

            AudioObjectSetPropertyData(
                currentDevice.audioDeviceID,
                &volumePropertyAddress,
                0,
                nil,
                volumeSize,
                &volume)
        }
    }
#endif
}

#if os(OSX)
private func propertyListener(objectID: UInt32,
                              numInAddresses: UInt32,
                              inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
                              clientData: UnsafeMutableRawPointer?) -> Int32 {
    let repository = AudioPlaybackRepository.instance
    let address = inAddresses.pointee

    switch address.mSelector {
    case kAudioObjectPropertyOwnedObjects:
        repository.getAudioDevices()

    case kAudioHardwarePropertyDefaultOutputDevice:
        repository.getDefaultDevice { device in
            if let device,
               repository.isUsingDefaultDevice {
                repository.currentDevice = device
            }
        }

    default:
        break
    }

    repository.syncVolume()

    return kAudioHardwareNoError
}
#endif

// iCloud: Ubiquitous Item Handling
extension AudioPlaybackRepository {
    @objc func gathered(notification: Notification?) {
        let query = notification?.object as? NSMetadataQuery

        query?.enumerateResults { (item: Any, _: Int, _: UnsafeMutablePointer<ObjCBool>) in
            let metadataItem = item as? NSMetadataItem
            let path = metadataItem?.value(forAttribute: NSMetadataItemPathKey) as? String

            if let metadataItem,
               let path,
               let currentURL,
               path.hasSuffix(currentURL.cleanFilename) {
                let isDownloaded = isMetadataItemDownloaded(item: metadataItem)

                debugPrint("isDownloaded: \(isDownloaded)")

                if isDownloaded {
                    if let query {
                        NotificationCenter.default.removeObserver(
                            self,
                            name: NSNotification.Name.NSMetadataQueryDidUpdate,
                            object: query
                        )
                        NotificationCenter.default.removeObserver(
                            self,
                            name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                            object: query
                        )
                        query.stop()
                        self.query = nil
                    }

                    DispatchQueue.main.async {
                        if !self.audioPlayer.isPlaying {
                            self.startPlayback(usingDownloadedAudio: currentURL)
                        }

                        self.isDownloading = false
                    }
                } else {
                    handleDownloadingStatus(for: metadataItem)
                }
            }
        }
    }

    private func startMetadataQuery(for url: URL, isAudio: Bool) {
        if let old = query {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidUpdate,
                object: old
            )
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                object: old
            )
            old.stop()
            query = nil
        }

        let query = NSMetadataQuery()
        if query.operationQueue == nil {
            query.operationQueue = operationQueue
        }
        let filename = url.cleanFilename
        debugPrint("filename: \(filename)")

        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K ENDSWITH %@", NSMetadataItemPathKey, filename)

        if self.query == nil {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(gathered),
                name: NSNotification.Name.NSMetadataQueryDidUpdate,
                object: query
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(gathered),
                name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                object: query
            )
        }

        DispatchQueue.main.async {
            self.downloadProgress = 0.0

            self.query = query
        }

        isDownloading = true

        query.start()
    }

#if os(OSX)
    private func handleNowPlayingInfo(_ track: Track?) {
        let mediaPlayerInfoCenter =  MPNowPlayingInfoCenter.default()

        mediaPlayerInfoCenter.nowPlayingInfo = [:]

        if let trackName = track?.name {
            mediaPlayerInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = trackName
        }

        if let artistName = track?.displayArtist {
            mediaPlayerInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = artistName
        }

        if let duration = track?.duration {
            mediaPlayerInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
        }

        if track != nil {
            if let album = self.currentAlbum,
               let url = LibraryRepository.instance.currentLibraryURL?.appending(path: "metadata")
                .appending(path: album.uuid)
                .appending(path: "artwork"),
               let imageView = Image(url: url) {
                mediaPlayerInfoCenter.nowPlayingInfo?[
                    MPMediaItemPropertyArtwork
                ] = MPMediaItemArtwork(
                    boundsSize: CGSize(width: 1024, height: 1024),
                    requestHandler: { newSize -> NSImage in
                        let image = DispatchQueue.main.sync {
                            let renderer = ImageRenderer(content: imageView)
                            renderer.proposedSize = ProposedViewSize(width: newSize.width, height: newSize.height)
                            return renderer.nsImage!
                        }
                        return image
                    }
                )
            } else {
                mediaPlayerInfoCenter.nowPlayingInfo?[
                    MPMediaItemPropertyArtwork
                ] = MPMediaItemArtwork(
                    boundsSize: CGSize(width: 1024, height: 1024),
                    requestHandler: { newSize -> NSImage in
                        let image = DispatchQueue.main.sync {
                            let renderer = ImageRenderer(content: ArtworkIcon())
                            renderer.proposedSize = ProposedViewSize(width: newSize.width, height: newSize.height)
                            return renderer.nsImage!
                        }
                        return image
                    }
                )
            }
            mediaPlayerInfoCenter.playbackState = .playing
        } else {
            mediaPlayerInfoCenter.playbackState = .stopped
        }
    }
#endif

#if os(iOS)
    private func handleNowPlayingInfo(_ track: Track?) {
        let mediaPlayerInfoCenter =  MPNowPlayingInfoCenter.default()

        mediaPlayerInfoCenter.nowPlayingInfo = [:]

        if let trackName = track?.name {
            mediaPlayerInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = trackName
        }

        if let artistName = track?.displayArtist {
            mediaPlayerInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = artistName
        }

        if let duration = track?.duration {
            mediaPlayerInfoCenter.nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = duration
        }

        if track != nil {
            if let album = self.currentAlbum,
               let url = LibraryRepository.instance.currentLibraryURL?.appending(path: "metadata")
                .appending(path: album.uuid)
                .appending(path: "artwork"),
               let data = try? Data(contentsOf: url),
               let raw  = UIImage(data: data) {
                mediaPlayerInfoCenter.nowPlayingInfo?[
                    MPMediaItemPropertyArtwork
                ] = MPMediaItemArtwork(boundsSize: raw.size, requestHandler: { newSize -> UIImage in
                    let renderer = UIGraphicsImageRenderer(size: newSize)
                    let image = renderer.image { _ in
                        raw.draw(in: CGRect.init(origin: CGPoint.zero, size: newSize))
                    }
                    return image.withRenderingMode(image.renderingMode)
                })
            } else {
                mediaPlayerInfoCenter.nowPlayingInfo?[
                    MPMediaItemPropertyArtwork
                ] = MPMediaItemArtwork(
                    boundsSize: CGSize(width: 1024, height: 1024),
                    requestHandler: { newSize -> UIImage in
                        let image = DispatchQueue.main.sync {
                            let renderer = ImageRenderer(content: ArtworkIcon())
                            renderer.proposedSize = ProposedViewSize(width: newSize.width, height: newSize.height)
                            return renderer.uiImage!
                        }
                        return image
                    }
                )
            }
        }
    }

    @objc func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            self.isPlaying = false

#if os(OSX)
            MPNowPlayingInfoCenter.default().playbackState = .paused
#endif

            self.timer.suspend()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                self.start()
            }
        default: ()
        }
    }
#endif

    private func isMetadataItemDownloaded(item: NSMetadataItem) -> Bool {
        if item.value(
            forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey
        ) as? String == NSMetadataUbiquitousItemDownloadingStatusCurrent {
            return true
        } else {
            return false
        }
    }

    private func handleDownloadingStatus(for item: NSMetadataItem) {
        if let percentage = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double {
            DispatchQueue.main.async {
                self.downloadProgress = percentage / 100.0
            }
        }
    }

    private func ubiquityURL(for track: Track, under album: Album) -> URL? {
        guard let currentURL = LibraryRepository.instance.ubiquityCurrentLibraryURL
        else {
            return nil
        }

        return currentURL
            .appending(path: "data/\(album.uuid)/\(track.disc)", directoryHint: .isDirectory)
            .appending(path: "\(track.filename)")
    }
}

extension AudioPlaybackRepository {
    private func updatePlaybackStatus() {
        if self.audioPlayer.isPlaying {
            DispatchQueue.main.async {
                let duration = max(self.audioPlayer.duration, 1)
                self.progress = self.audioPlayer.currentTime / duration
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[
                MPNowPlayingInfoPropertyElapsedPlaybackTime
            ] = self.audioPlayer.currentTime
        }
    }

#if os(OSX)
    private func volume(of device: OutputAudioDevice) -> Float? {
        var volume = Float32(0.0)
        var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))

        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)

        let status = AudioObjectGetPropertyData(
            device.audioDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volumeSize,
            &volume)

        if status != noErr {
            return nil
        }

        return volume
    }
#endif

    private func initUserDefaults(_ userDefaults: UserDefaults) {
        DispatchQueue.main.sync {
            if let userDefaultsIsShuffle {
                isShuffle = userDefaultsIsShuffle
            }

            if let userDefaultsIsLoop {
                isLoop = userDefaultsIsLoop
            }

            if let currentTrackID = userDefaultsCurrentTrackID {
                currentTrack = LibraryRepository.instance.track(of: currentTrackID)
                if let currentTrack {
                    currentAlbum = LibraryRepository.instance.album(of: currentTrack.albumID)
                }
            }
        }
    }

    private func nextPlaylist() -> [Track]? {
        if let playlist,
           isShuffle {
            return playlist.shuffled()

        }

        if let currentAlbum {
            return LibraryRepository.instance.tracks(for: currentAlbum)
        }

        return nil
    }

    private func updateUserDefaults() {
        userDefaults?.set(currentTrack?.id, forKey: "AUDIO_PLAYER_CURRENT_TRACK")
    }

    private func play() {
        guard let currentTrack,
              let currentAlbum = LibraryRepository.instance.album(of: currentTrack.albumID),
              let audio = ubiquityURL(for: currentTrack, under: currentAlbum)
        else {
            return
        }

        beginPlayback(of: audio)
    }

    @objc private func togglePlayer(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        toggle()
        return .success
    }

    private func startPlayback(usingDownloadedAudio audio: URL) {
        do {
#if os(iOS)
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(.playback,
                                    mode: .default,
                                    policy: .longFormAudio,
                                    options: [])
            try session.setActive(true)

            engine.stop()
            player.stop()

#endif
            audioPlayer = try AVAudioPlayer(contentsOf: audio)
            audioPlayer.delegate = self

#if os(iOS)
            try session.setPreferredSampleRate(audioPlayer.format.sampleRate)
            try session.setPreferredOutputNumberOfChannels(Int(audioPlayer.format.channelCount))

            try session.setActive(true)

            if !isObservingPlayback {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleAudioSessionInterruption),
                    name: AVAudioSession.interruptionNotification,
                    object: nil
                )
                isObservingPlayback = true
            }

            UIApplication.shared.beginReceivingRemoteControlEvents()
#endif

            let mediaPlayerCommandCenter = MPRemoteCommandCenter.shared()
            mediaPlayerCommandCenter.previousTrackCommand.addTarget { _ in
                self.prev()
                return .success
            }
            mediaPlayerCommandCenter.nextTrackCommand.addTarget { _ in
                self.next()
                return .success
            }
            mediaPlayerCommandCenter.pauseCommand.addTarget { _ in
                self.pause()
                return .success
            }
            mediaPlayerCommandCenter.playCommand.addTarget { _ in
                self.start()
                return .success
            }
            mediaPlayerCommandCenter.togglePlayPauseCommand.addTarget(handler: togglePlayer)
            mediaPlayerCommandCenter.changePlaybackPositionCommand.addTarget { event in
                if let event = event as? MPChangePlaybackPositionCommandEvent,
                   let currentTrack = self.currentTrack {
                    let time = Double(event.positionTime) / Double(currentTrack.duration)
                    self.seek(time)
                }

                return .success
            }

            handleNowPlayingInfo(currentTrack)
            audioPlayer.play()

            debugPrint("\(#function): playing(\(audio)), using \(audioPlayer.format)")

            if !isPlaying {
                timer.resume()
            }

            self.isPlaying = true

            updateUserDefaults()
        } catch {
            debugPrint(#function, error)
        }
    }

    private func beginPlayback(of audio: URL) {
        audioPlayer.pause()
        progress = 0

        handleNowPlayingInfo(nil)
        let mediaPlayerCommandCenter = MPRemoteCommandCenter.shared()
        mediaPlayerCommandCenter.previousTrackCommand.removeTarget(nil)
        mediaPlayerCommandCenter.nextTrackCommand.removeTarget(nil)
        mediaPlayerCommandCenter.pauseCommand.removeTarget(nil)
        mediaPlayerCommandCenter.playCommand.removeTarget(nil)
        mediaPlayerCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        mediaPlayerCommandCenter.changePlaybackPositionCommand.removeTarget(nil)

#if os(iOS)
        UIApplication.shared.endReceivingRemoteControlEvents()

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback,
                                     mode: .default,
                                     policy: .longFormAudio,
                                     options: [])
            try session.setActive(true)
            try engine.start()
        } catch {}
        player.play()
#endif

        DispatchQueue.main.async {
            self.currentURL = audio
            self.startMetadataQuery(for: audio, isAudio: true)
            try? FileManager.default.startDownloadingUbiquitousItem(at: audio.iCloud)
        }
    }

#if os(OSX)
    private func registerForNotifications() {
        if isRegisteredForNotifications {
            unregisterForNotifications()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

        if noErr == AudioObjectAddPropertyListener(systemObjectID, &address, propertyListener, nil) {
            isRegisteredForNotifications = true
        }
    }

    private func unregisterForNotifications() {
        guard isRegisteredForNotifications else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertySelectorWildcard,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )

        let systemObjectID = AudioObjectID(kAudioObjectSystemObject)

        if noErr == AudioObjectRemovePropertyListener(systemObjectID, &address, propertyListener, nil) {
            isRegisteredForNotifications = false
        }
    }
#endif
}

#if os(OSX)
extension AudioPlaybackRepository {
    @objc func volumeChangeEvent(_ event: NSEvent) {
        syncVolume()
    }

    private func observeSystemVolume() {
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeChangeEvent(_:)),
            name: NSNotification.Name(rawValue: "com.apple.sound.settingsChangedNotification"),
            object: nil
        )
    }

    private func unregisterSystemVolumeObserver() {
        DistributedNotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rawValue: "com.apple.sound.settingsChangedNotification"),
            object: nil
        )
    }
}
#endif

extension AudioPlaybackRepository: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            self.next()
        }
    }
}
