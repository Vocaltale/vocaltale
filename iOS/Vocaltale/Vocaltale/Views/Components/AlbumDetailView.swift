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
                ForEach(discs, id: \.self) { disc in
                    if discs.count > 1 {
                        Text(String(format: NSLocalizedString("album_disc_label", comment: ""), disc))
                            .font(.title3)
                            .bold()
                    }

                    ForEach(tracks(for: disc), id: \.id) { track in
                        TrackListItem(
                            track: track,
                            selected: selected ?? audioPlayerRepository.currentTrack == track
                        ) {
                            if selected ?? audioPlayerRepository.currentTrack == track {
                                let tracks = libraryRepository.tracks(for: album)

                                audioPlayerRepository.play(
                                    tracks,
                                    of: album,
                                    from: track
                                )

                                selected = nil
                            } else {
                                selected = track
                            }
                        }

                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 88, trailing: 16))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(audioPlayerRepository.$currentTrack) { _ in
            selected = nil
        }
    }
    //    var body: some View {
    //        ScrollView {
    //            AlbumView(album: album)
    //
    //        }
    //    }
}
