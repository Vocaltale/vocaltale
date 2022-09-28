//
//  PlayerControlView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

struct PlayerControlView: View {
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance

    @State private var progressOverride: Double?
    @State private var displayHover: Bool = false

    private var album: Album? {
        return audioPlayerRepository.currentAlbum
    }

    private var artworkURL: URL? {
        if let album {
            return libraryRepository.currentLibraryURL?.appending(path: "metadata")
                .appending(path: album.uuid)
                .appending(path: "artwork")
        }

        return nil
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

    var body: some View {
        VStack(alignment: .center) {
            Group {
                if let album {
                    TrackView(track: audioPlayerRepository.currentTrack, album: album)
                        .contextMenu {
                            ForEach(libraryRepository.tracks(for: album)) { track in
                                Button(track.name ?? NSLocalizedString("track_unknown", comment: "")) {
                                    audioPlayerRepository.play(track)
                                }
                            }
                        } preview: {
                            Group {
                                if let artworkURL,
                                   let image = Image(url: artworkURL) {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    ZStack {
                                        Rectangle()
                                            .fill(.secondary.opacity(0.5))
                                            .aspectRatio(1, contentMode: .fit)
                                            .frame(maxWidth: 1024, maxHeight: 1024, alignment: .center)
                                        Image(systemName: "music.note")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundColor(.white)
                                            .padding(.all, 16)
                                            .frame(maxWidth: 1024, maxHeight: 1024)
                                    }
                                }
                            }                        }

                } else {
                    TrackView(track: audioPlayerRepository.currentTrack, album: album)
                }
            }
            .frame(
                maxWidth: 0.8 * (windowRepository.geometry?.size.width ?? 0),
                maxHeight: 0.6 * (windowRepository.geometry?.size.height ?? 0)
            )
            DraggableTimeline(progressOverride: $progressOverride)
                .frame(height: kDraggableTimelineHeight_iOS)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .center,
                spacing: 0
            ) {
                ShuffleButton()
                Spacer()
                BackwardButton()
                Spacer()
                PlayPauseButton()
                Spacer()
                ForwardButton()
                Spacer()
                LoopButton()
            }
            .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
        }
    }
}

struct PlayerControlView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlView()
    }
}
