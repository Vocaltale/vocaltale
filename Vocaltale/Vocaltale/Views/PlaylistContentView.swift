//
//  PlaylistContentView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import SwiftUI

private struct PlaylistContentBackgroundDropDelegate: DropDelegate {
    @Binding var dragged: PlaylistItem?
    @Binding var playlist: [PlaylistItem]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: playlist.compactMap({ item in
            item.playlistTrack
        }))

        self.dragged = nil

        WindowRepository.instance.isChildDragging = false

        return true
    }
}

private struct PlaylistContentDropDelegate: DropDelegate {
    let item: PlaylistItem
    @Binding var dragged: PlaylistItem?
    @Binding var playlist: [PlaylistItem]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private func reorder() {
        guard let dragged
        else {
            return
        }

        if let from = playlist.firstIndex(of: dragged),
           let to = playlist.firstIndex(of: item),
           from != to {
            playlist.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        reorder()
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: playlist.compactMap({ item in
            item.playlistTrack
        }))

        self.dragged = nil

        WindowRepository.instance.isChildDragging = false

        return true
    }
}
struct PlaylistContentView: View {
    let playlist: Playlist

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance
    @State private var selected: PlaylistTrack?
    @State private var currentTracks: [PlaylistItem] = []
    @State private var dragged: PlaylistItem?

    private func tracks() -> [PlaylistItem] {
        let playlistTracks = libraryRepository.tracks(for: playlist)
            .sorted { a, b in
                a.order < b.order
            }
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
                ForEach(currentTracks, id: \.id) { item in
                    TrackListItem(
                        item: item,
                        order: item.playlistTrack?.order ?? item.track.track,
                        playlist: playlist,
                        selected: selected ?? audioPlayerRepository.currentPlaylistTrack == item.playlistTrack
                    ) {
                        if selected ??
                            audioPlayerRepository.currentPlaylistTrack == item.playlistTrack {
                            let playlistTracks = tracks()

                            audioPlayerRepository.play(
                                playlistTracks,
                                from: item.track,
                                with: item.playlistTrack,
                                newPlaylist: true
                            )

                            selected = nil
                        } else {
                            selected = item.playlistTrack
                        }
                    }
                    .onDrag {
                        WindowRepository.instance.isChildDragging = true
                        dragged = item
                        return NSItemProvider(object: item.id as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: PlaylistContentDropDelegate(
                            item: item,
                            dragged: $dragged,
                            playlist: $currentTracks
                        )
                    )
                    .animation(.default, value: currentTracks)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(
            of: [.text],
            delegate: PlaylistContentBackgroundDropDelegate(
                dragged: $dragged,
                playlist: $currentTracks
            )
        )
        .onChange(of: libraryRepository.playlistTracks) { _ in
            currentTracks = tracks()
        }
        .onAppear {
            currentTracks = tracks()
        }
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
