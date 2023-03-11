//
//  AlbumDetailView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

struct AlbumDetailView: View {
    let album: Album

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var selected: Track?

    private var discs: [Int] {
        var set = Set<Int>()

        for track in libraryRepository.tracks(for: album) {
            let disc = track.disc
            set.insert(disc)
        }

        return set.sorted()
    }

    private func tracks(for disc: Int) -> [Track] {
        return libraryRepository.tracks(for: album).filter { track in
            track.disc == disc
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading
            ) {
                AlbumView(album: album)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                ForEach(discs, id: \.self) { disc in
                    if discs.count > 1 {
                        Text(String(format: NSLocalizedString("album_disc_label", comment: ""), disc))
                            .font(.title3)
                            .bold()
                    }

                    ForEach(tracks(for: disc), id: \.id) { track in
                        TrackListItem(
                            item: PlaylistItem(track: track, playlistTrack: nil),
                            order: track.track,
                            playlist: nil,
                            selected: selected ?? audioPlayerRepository.currentTrack == track
                        ) {
                            if selected ?? audioPlayerRepository.currentTrack == track {
                                audioPlayerRepository.play(
                                    album: album,
                                    from: track,
                                    newPlaylist: true
                                )

                                selected = nil
                            } else {
                                selected = track
                            }
                        }

                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .navigationTitle(album.displayName)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(audioPlayerRepository.$currentTrack) { _ in
            selected = nil
        }
    }
}
