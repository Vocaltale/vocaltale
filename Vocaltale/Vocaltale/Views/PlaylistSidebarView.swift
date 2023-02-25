//
//  PlaylistSidebarView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import SwiftUI
import UniformTypeIdentifiers

private let kAlbumNameHorizontalPadding: CGFloat = 12.0

private struct PlaylistNameView: View {
    let playlist: Playlist

    @Binding var dragged: Playlist?

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @State private var isFocused: Bool = false

    var body: some View {
        HStack {
            Text(playlist.name)
            Spacer()
        }
        .padding(
            EdgeInsets(
                top: 6,
                leading: kAlbumNameHorizontalPadding,
                bottom: 6,
                trailing: kAlbumNameHorizontalPadding
            )
        )
        .background(
            (
                libraryRepository.currentPlaylistID == playlist.id ? Color.accentColor.opacity(0.5) : Color.clear
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct PlaylistSidebarBackgroundDropDelegate: DropDelegate {
    @Binding var dragged: Playlist?
    @Binding var playlists: [Playlist]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: playlists)

        self.dragged = nil
        return true
    }
}

private struct PlaylistSidebarDropDelegate: DropDelegate {
    let item: Playlist
    @Binding var dragged: Playlist?
    @Binding var playlists: [Playlist]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private func reorder() {
        guard let dragged
        else {
            return
        }

        if let from = playlists.firstIndex(of: dragged),
           let to = playlists.firstIndex(of: item),
           from != to {
            playlists.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        reorder()
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: playlists)

        self.dragged = nil

        WindowRepository.instance.isChildDragging = false

        return true
    }
}

struct PlaylistSidebarView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @Binding var category: SidebarCategory

    @State private var myAlbumsCollapsed = false
    @State private var dragged: Playlist?
    @State private var playlists: [Playlist] = []

    var body: some View {
        VStackLayout(alignment: .leading, spacing: 2) {
            ForEach(playlists, id: \.id) { playlist in
                PlaylistNameView(playlist: playlist, dragged: $dragged)
                    .onTapGesture {
                        libraryRepository.currentPlaylist = playlist
                    }
                    .onDrag {
                        WindowRepository.instance.isChildDragging = true
                        dragged = playlist
                        return NSItemProvider(object: playlist.uuid as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: PlaylistSidebarDropDelegate(item: playlist, dragged: $dragged, playlists: $playlists)
                    )
            }
        }
        .animation(.default, value: playlists)
        .onDrop(of: [.text], delegate: PlaylistSidebarBackgroundDropDelegate(dragged: $dragged, playlists: $playlists))
        .onChange(of: libraryRepository.currentPlaylistID) { id in
            if let id {
                libraryRepository.currentPlaylist = libraryRepository.playlist(of: id)
                category = .playlist
            }
        }
        .onChange(of: libraryRepository.playlists) { value in
            playlists = value
        }
        .onAppear {
            playlists = libraryRepository.playlists
        }
    }
}

struct PlaylistSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
