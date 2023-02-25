//
//  PlaylistContentView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import SwiftUI

struct PlaylistContentView: View {
    let playlist: Playlist

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var selected: PlaylistTrack?

    private func tracks() -> [PlaylistItem] {
        let playlistTracks = libraryRepository.tracks(for: playlist)
        let ids = playlistTracks.map { playlistTrack in
            playlistTrack.trackID
        }

        let tracks = libraryRepository.tracks.filter { track in
            ids.contains(track.id)
        }

        return playlistTracks.compactMap { playlistTrack in
            if let result = tracks.first(where: { track in
                track.id == playlistTrack.trackID
            }) {
                return PlaylistItem(track: result, playlistTrack: playlistTrack)
            }

            return nil
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading
            ) {
                ForEach(tracks(), id: \.id) { item in
                    TrackListItem(
                        track: item.track,
                        order: item.playlistTrack?.order ?? item.track.track,
                        selected: selected ?? audioPlayerRepository.currentPlaylistTrack == item.playlistTrack
                    ) {
                        if selected ??
                            audioPlayerRepository.currentPlaylistTrack == item.playlistTrack {
                            let playlistTracks = tracks()

                            audioPlayerRepository.play(
                                playlistTracks,
                                from: item.track,
                                with: item.playlistTrack
                            )

                            selected = nil
                        } else {
                            selected = item.playlistTrack
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(audioPlayerRepository.$currentPlaylistTrack) { _ in
            selected = nil
        }
    }
}

struct PlaylistContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}