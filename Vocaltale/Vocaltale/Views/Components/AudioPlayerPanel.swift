//
//  AudioPlayerPanel.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/9.
//

import SwiftUI

struct AudioPlayerPanel: View {
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @ObservedObject private var libraryRepository = LibraryRepository.instance

    @State private var progressOverride: Double?
    @State private var displayHover: Bool = false

    private var album: Album? {
        get {
            audioPlayerRepository.currentAlbum
        }
    }

    private var artworkURL: URL? {
        get {
            if let album {
                return libraryRepository.currentLibraryURL?.appending(path: "metadata")
                    .appending(path: album.uuid)
                    .appending(path: "artwork")
            }

            return nil
        }
    }

    private var currentTime: String? {
        let progress = progressOverride ?? audioPlayerRepository.progress

        if let track = audioPlayerRepository.currentTrack {
            let seconds = Int64(progress * Double(track.duration))
            let duration = Duration(secondsComponent: seconds, attosecondsComponent: 0)

            return duration.formatted(.time(pattern: .minuteSecond))
        }

        return nil
    }

    private var totalTime: String? {
        if let track = audioPlayerRepository.currentTrack {
            let seconds = Int64(track.duration)
            let duration = Duration(secondsComponent: seconds, attosecondsComponent: 0)

            return duration.formatted(.time(pattern: .minuteSecond))
        }

        return nil
    }

    private var display: some View {
        HStack(spacing: .zero) {
            if let artworkURL,
               let image = Image(url: artworkURL) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 48)
            } else {
                ZStack {
                    Rectangle()
                        .fill(.secondary.opacity(0.5))
                        .aspectRatio(1, contentMode: .fit)
                    Image(systemName: "music.note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }
                .frame(width: 48, height: 48)
            }
            VStack(spacing: .zero) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .foregroundColor(displayHover ? .secondary.opacity(0.2) : .clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.default, value: displayHover)

                    if let track = audioPlayerRepository.currentTrack {
                        VStack(alignment: .center) {
                            Text(track.displayName)
                                .font(.system(Font.TextStyle.body))
                                .bold()
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            Text(track.displayArtist)
                                .font(.system(Font.TextStyle.caption))
                                .foregroundColor(Color.secondary)
                                .lineLimit(1)
                        }
                        .padding(EdgeInsets(top: 0, leading: 8, bottom: 4, trailing: 8))
                    }
                    HStack(alignment: .bottom) {
                        if let currentTime {
                            Text(currentTime)
                                .font(.system(Font.TextStyle.caption))
                                .foregroundColor(.secondary.opacity(0.75))
                                .lineLimit(1)
                        }
                        Spacer()
                        if let totalTime {
                            Text(totalTime)
                                .font(.system(Font.TextStyle.caption))
                                .foregroundColor(.secondary.opacity(0.75))
                                .lineLimit(1)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 4, trailing: 8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onHover { value in
                    displayHover = value
                }
                .onTapGesture {
                    if let playlist = audioPlayerRepository.currentPlaylist {
                        libraryRepository.currentPlaylist = playlist
                    } else {
                        libraryRepository.currentAlbum = audioPlayerRepository.currentAlbum
                    }
                }
                DraggableTimeline(progressOverride: $progressOverride)
                    .frame(height: kDraggableTimelineHeight_macOS)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: 48)
        .background(Color.secondary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    var body: some View {
        HStack(
            alignment: .center,
            spacing: 12
        ) {
            Spacer()
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .center,
                spacing: 4
            ) {
                ShuffleButton()
                BackwardButton()
                PlayPauseButton()
                ForwardButton()
                LoopButton()
            }
            .frame(width: 192)
            Spacer()
            display
                .frame(minWidth: 360, maxWidth: 480)
            Spacer()
            LazyVGrid(
                columns: [
                    GridItem(.fixed(24)),
                    GridItem(.flexible()),
                    GridItem(.fixed(24))
                ],
                alignment: .center,
                spacing: 4
            ) {
                VolumeDownButton()
                Slider(value: $audioPlayerRepository.volume)
                    .frame(maxWidth: .infinity)
                    .disabled(!audioPlayerRepository.volumeControllable)
                    .onChange(of: audioPlayerRepository.volume) { _ in
                        audioPlayerRepository.setSystemVolume()
                    }
                VolumeUpButton()
            }
            .frame(width: 192)
            Spacer()
        }
        .padding(.horizontal, 32.0)
        .draggingWindow()
        .frame(maxWidth: .infinity, maxHeight: 72, alignment: .center)
    }
}

struct AudioPlayerPanel_Previews: PreviewProvider {
    static var previews: some View {
        AudioPlayerPanel()
    }
}
