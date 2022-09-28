//
//  ControlButtons.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

private let kControlButtonsPaddings = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

struct LoopButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor((hover ? Color.secondary.opacity(0.2) : .clear))
            Image(systemName: "repeat")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(audioPlayerRepository.isLoop ? .primary : Color.secondary)
                .padding(kControlButtonsPaddings)
        }
        .onHover { value in
            hover = value
        }
        .onTapGesture {
            audioPlayerRepository.setLoop(!audioPlayerRepository.isLoop)
        }
    }
}

struct ShuffleButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor((hover ? Color.secondary.opacity(0.2) : .clear))
            Image(systemName: "shuffle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(audioPlayerRepository.isShuffle ? .primary : Color.secondary)
                .padding(kControlButtonsPaddings)
        }
        .onHover { value in
            hover = value
        }
        .onTapGesture {
            audioPlayerRepository.setShuffle(!audioPlayerRepository.isShuffle)
        }
    }
}

struct BackwardButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false
    var body: some View {
        if audioPlayerRepository.currentTrack != nil {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor((hover ? Color.secondary.opacity(0.2) : .clear))
                Image(systemName: "backward.end.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primary)
                    .padding(kControlButtonsPaddings)
            }
            .onHover { value in
                hover = value
            }
            .onTapGesture {
                audioPlayerRepository.rewind()
            }
        } else {
            Image(systemName: "backward.end.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.secondary)
                .padding(kControlButtonsPaddings)
        }
    }
}

struct ForwardButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false
    var body: some View {
        if audioPlayerRepository.currentTrack != nil {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor((hover ? Color.secondary.opacity(0.2) : .clear))
                Image(systemName: "forward.end.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primary)
                    .padding(kControlButtonsPaddings)
            }
            .onHover { value in
                hover = value
            }
            .onTapGesture {
                audioPlayerRepository.next()
            }
        } else {
            Image(systemName: "forward.end.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.secondary)
                .padding(kControlButtonsPaddings)
        }
    }
}

private let kPlayNowButtonPadding = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

struct PlayNowButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false

    private var systemName: String {
        return "arrowtriangle.right.fill"
    }

    private var button: some View {
        Button {
            if let album = libraryRepository.currentAlbum {
                audioPlayerRepository.play(album: album)
            }
        } label: {
            HStack(alignment: .center) {
                Image(systemName: systemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primary)
                    .padding(kPlayNowButtonPadding)
                Text(NSLocalizedString("album_play_now", comment: ""))
                    .font(.title2)
                    .padding(.all, 8)
            }
            .background(
                (hover ? Color.secondary.opacity(0.2) : .clear)
                    .contentShape(
                        RoundedRectangle(cornerRadius: 8)
                    )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
            .onHover { value in
                hover = value
            }
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        if audioPlayerRepository.isDownloading {
            CircularProgressView(
                progress: audioPlayerRepository.downloadProgress,
                width: 4,
                foreground: .accentColor
            )
        } else if libraryRepository.currentAlbum != nil || audioPlayerRepository.isPlaying {
            button
        } else {
            HStack(alignment: .center) {
                Group {
                    Image(systemName: "arrowtriangle.right.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .aspectRatio(1, contentMode: .fit)
                Text(NSLocalizedString("album_play_now", comment: ""))
                    .font(.title2)
                    .padding(.all, 12)
            }
            .padding(kPlayNowButtonPadding)
            .foregroundColor(Color.secondary)
        }
    }
}

struct PlayPauseButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false

    private var systemName: String {
        if audioPlayerRepository.isPlaying {
            return "pause.fill"
        }

        return "arrowtriangle.right.fill"
    }

    private var button: some View {
        Button {
            audioPlayerRepository.toggle()
        } label: {
            HStack(alignment: .center) {
                Image(systemName: systemName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor(.primary)
                    .padding(kControlButtonsPaddings)
            }
            .background(
                (hover ? Color.secondary.opacity(0.2) : .clear)
                    .contentShape(
                        RoundedRectangle(cornerRadius: 8)
                    )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
        }
        .onHover { value in
            hover = value
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        if audioPlayerRepository.isDownloading {
            CircularProgressView(
                progress: audioPlayerRepository.downloadProgress,
                width: 4,
                foreground: .accentColor
            )
            .padding(kControlButtonsPaddings)
        } else if libraryRepository.currentAlbum != nil || audioPlayerRepository.currentTrack != nil {
            button
                .keyboardShortcut(.space, modifiers: [])
        } else {
            HStack(alignment: .center) {
                Image(systemName: "arrowtriangle.right.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .padding(kControlButtonsPaddings)
            .foregroundColor(Color.secondary)
        }
    }
}

struct VolumeDownButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false
    var body: some View {
        if audioPlayerRepository.volumeControllable {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor((hover ? Color.secondary.opacity(0.2) : .clear))
                Image(systemName: "minus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primary)
                    .padding(kControlButtonsPaddings)
            }
            .onHover { value in
                hover = value
            }
            .onTapGesture {
                audioPlayerRepository.decrementVolume()
            }
        } else {
            Image(systemName: "minus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.secondary)
                .padding(kControlButtonsPaddings)
        }
    }
}

struct VolumeUpButton: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var hover = false
    var body: some View {
        if audioPlayerRepository.volumeControllable {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor((hover ? Color.secondary.opacity(0.2) : .clear))
                Image(systemName: "plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.primary)
                    .padding(kControlButtonsPaddings)
            }
            .onHover { value in
                hover = value
            }
            .onTapGesture {
                audioPlayerRepository.incrementVolume()
            }
        } else {
            Image(systemName: "plus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color.secondary)
                .padding(kControlButtonsPaddings)
        }
    }
}
