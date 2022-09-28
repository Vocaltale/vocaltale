//
//  LibraryView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/28.
//

import SwiftUI
import UniformTypeIdentifiers

private let kAlbumNameHorizontalPadding: CGFloat = 12.0

private struct AlbumNameView: View {
    let album: Album

    @Binding var dragged: Album?

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @State private var isFocused: Bool = false

    var body: some View {
        HStack {
            Text(album.displayName)
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
                libraryRepository.currentAlbumID == album.id ? Color.accentColor.opacity(0.5) : Color.clear
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct AlbumSidebarBackgroundDropDelegate: DropDelegate {
    @Binding var dragged: Album?
    @Binding var albums: [Album]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: albums)

        self.dragged = nil
        return true
    }
}

private struct AlbumSidebarDropDelegate: DropDelegate {
    let item: Album
    @Binding var dragged: Album?
    @Binding var albums: [Album]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private func reorder() {
        guard let dragged
        else {
            return
        }

        if let from = albums.firstIndex(of: dragged),
           let to = albums.firstIndex(of: item),
           from != to {
            albums.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        reorder()
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: albums)

        self.dragged = nil

        WindowRepository.instance.isChildDragging = false

        return true
    }
}

struct AlbumSidebarView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @Binding var category: SidebarCategory

    @State private var myAlbumsCollapsed = false
    @State private var dragged: Album?
    @State private var albums: [Album] = []

    var body: some View {
        VStackLayout(alignment: .leading, spacing: 2) {
            ForEach(albums, id: \.id) { album in
                AlbumNameView(album: album, dragged: $dragged)
                    .onTapGesture {
                        libraryRepository.currentAlbum = album
                    }
                    .contextMenu {
                        AlbumContextMenu(album: album)
                    }
                    .onDrag {
                        WindowRepository.instance.isChildDragging = true
                        dragged = album
                        return NSItemProvider(object: album.uuid as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: AlbumSidebarDropDelegate(item: album, dragged: $dragged, albums: $albums)
                    )
            }
        }
        .animation(.default, value: albums)
        .onDrop(of: [.text], delegate: AlbumSidebarBackgroundDropDelegate(dragged: $dragged, albums: $albums))
        .onChange(of: libraryRepository.currentAlbumID) { id in
            if let albumID = id {
                libraryRepository.currentAlbum = libraryRepository.album(of: albumID)
                category = .album
            }
        }
        .onChange(of: libraryRepository.albums) { value in
            albums = value
        }
        .onAppear {
            albums = libraryRepository.albums
        }
    }
}

struct AlbumSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
