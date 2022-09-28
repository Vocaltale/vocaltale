//
//  AlbumListContentView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/10.
//

import SwiftUI

private struct AlbumListContentBackgroundDropDelegate: DropDelegate {
    @Binding var dragged: Album?
    @Binding var albums: [Album]

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        libraryRepository.reorder(to: albums)

        self.dragged = nil

        WindowRepository.instance.isChildDragging = false

        return true
    }
}

private struct AlbumListContentDropDelegate: DropDelegate {
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

struct AlbumListContentView: AlbumCardListViewMixins, View {
    @ObservedObject internal var libraryRepository = LibraryRepository.instance
    @State internal var albums: [Album] = []
    @State private var dragged: Album?
    @State private var selectedAlbumID: String?
    @State internal var size: CGSize = .zero

    var body: some View {
        VStack {
            switch libraryRepository.event.state {
            case .loaded:
                albumContentView
            default:
                EmptyView()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .onChange(of: libraryRepository.albums) { value in
            albums = value
        }
        .onAppear {
            albums = libraryRepository.albums
        }
    }

    internal var albumContentView: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(
                    columns: .init(
                        repeating: GridItem(
                            .flexible(),
                            spacing: kAlbumListSpacing,
                            alignment: .leading
                        ),
                        count: albumColumn
                    ),
                    alignment: .leading
                ) {
                    ForEach(albums, id: \.id) { album in
                        AlbumCardView(album: album)
                            .frame(alignment: .center)
                            .padding(
                                EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                            )
                            .background(
                                (selectedAlbumID == album.uuid ? Color.accentColor.opacity(0.5) : Color.clear)
                                    .contentShape(RoundedRectangle(cornerRadius: 8.0))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8.0))
                            .onTapGesture {
                                if selectedAlbumID == album.uuid {
                                    libraryRepository.currentAlbum = album
                                } else {
                                    selectedAlbumID = album.uuid
                                }
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
                                delegate: AlbumListContentDropDelegate(item: album, dragged: $dragged, albums: $albums)
                            )
                            .animation(.default, value: albums)
                    }
                    ForEach(0..<(albumColumn - (albums.count % albumColumn)), id: \.self) { _ in
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, kAlbumListSpacing + 12)
                Spacer()
            }
            .onTapGesture {
                selectedAlbumID = nil
            }
            .onDrop(of: [.text], delegate: AlbumListContentBackgroundDropDelegate(dragged: $dragged, albums: $albums))
            .onChange(of: geometry.size) { value in
                size = value
            }
            .onAppear {
                size = geometry.size
            }
        }
    }
}

struct AlbumListContentView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumListContentView()
    }
}
