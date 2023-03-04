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
        if let album = audioPlayerRepository.currentAlbum {
            return album
        }

        if let playlistTrack = audioPlayerRepository.currentPlaylistTrack,
           let track = libraryRepository.track(of: playlistTrack.trackID),
           let album = libraryRepository.album(of: track.albumID) {
            return album
        }

        return nil
    }

//    private var playlist: Playlist? {
//        return libraryRepository.currentPlaylist
//    }

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

    private var playlist: [PlaylistItem] {
        if let currentPlaylist = audioPlayerRepository.playlist {
            return currentPlaylist
        }

        if let currentPlaylist = libraryRepository.currentPlaylist {
            let playlistTracks = libraryRepository.tracks(for: currentPlaylist)
            let ids = playlistTracks.map { $0.trackID }
            let tracks = libraryRepository.tracks.filter { track in
                ids.contains(track.id)
            }

            return playlistTracks.compactMap { playlistTrack in
                if let track = tracks.first(where: { track in
                    track.id == playlistTrack.trackID
                }) {
                    return PlaylistItem(track: track, playlistTrack: playlistTrack)
                }

                return nil
            }
        }

        if let currentAlbum = libraryRepository.currentAlbum {
            let tracks = libraryRepository.tracks.filter { track in
                track.albumID == currentAlbum.id
            }

            return tracks.map { track in
                return PlaylistItem(track: track, playlistTrack: nil)
            }
        }

        return []
    }

    var body: some View {
        VStack(alignment: .center) {
            Group {
                if let album {
                    TrackView(track: audioPlayerRepository.currentTrack, album: album)
                        .contextMenu {
                            ForEach(playlist, id: \.id) { item in
                                Button(item.track.name ?? NSLocalizedString("track_unknown", comment: "")) {
                                    audioPlayerRepository.play(
                                        playlist,
                                        from: item.track,
                                        with: item.playlistTrack,
                                        newPlaylist: true
                                    )
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
                            }
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded({ _ in
                                windowRepository.isShowingPlayerSheet = false
                                if let currentPlaylist = libraryRepository.currentPlaylist {
                                    windowRepository.selectedTabTag = .playlist
                                    libraryRepository.currentPlaylist = currentPlaylist
                                    libraryRepository.currentAlbum = nil
                                    windowRepository.navigationPath.setPlaylist(currentPlaylist)
                                } else {
                                    windowRepository.selectedTabTag = .library
                                    libraryRepository.currentPlaylist = nil
                                    libraryRepository.currentAlbum = album
                                    windowRepository.navigationPath.setAlbum(album)
                                }
                            })
                        )

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
