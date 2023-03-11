//
//  AlbumGridView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
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

        if let fromIndex = albums.firstIndex(of: dragged),
           let toIndex = albums.firstIndex(of: item),
           fromIndex != toIndex {
            albums.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
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

        return true
    }
}

struct AlbumGridView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var selectedTrack: Track?

    private func tracks(for disc: Int, of album: Album) -> [Track] {
        return libraryRepository.tracks(for: album).filter { track in
            track.disc == disc
        }
    }

    @State internal var albums: [Album] = []
    @State private var dragged: Album?
    var body: some View {
        NavigationStack(path: $windowRepository.libraryPath) {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: kCurrentAudioPanelHeight, maximum: .infinity)),
                    GridItem(.flexible(minimum: kCurrentAudioPanelHeight, maximum: .infinity))
                ], content: {
                    ForEach(albums, id: \.id) { album in
                        NavigationLink(value: album) {
                            AlbumCardView(album: album)
                                .foregroundColor(Color.primary)
                                .frame(alignment: .center)
                                .padding(
                                    EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                                .onDrag {
                                    dragged = album
                                    return NSItemProvider(object: album.uuid as NSString)
                                }
                                .onDrop(
                                    of: [.text],
                                    delegate: AlbumListContentDropDelegate(
                                        item: album,
                                        dragged: $dragged,
                                        albums: $albums
                                    )
                                )
                                .animation(.default, value: albums)
                        }.simultaneousGesture(
                            TapGesture().onEnded({ _ in
                                libraryRepository.currentPlaylist = nil
                                libraryRepository.currentAlbum = album
                            })
                        )
                    }
                    .onChange(of: libraryRepository.albums) { value in
                        albums = value
                    }
                    .onAppear {
                        albums = libraryRepository.albums
                    }
                    if (albums.count % 2) == 1 {
                        Spacer()
                    }
                })
            }
            .safeAreaInset(edge: .bottom) {
                CurrentAudioPanel()
                    .frame(maxWidth: .infinity, maxHeight: kCurrentAudioPanelHeight)
                    .background(
                        VisualEffectView(
                            effect: UIBlurEffect(style: .regular)
                        )
                    )
                    .onTapGesture {
                        windowRepository.isShowingPlayerSheet = true
                    }
            }
            .navigationDestination(for: Album.self) { album in
                AlbumDetailView(album: album)
                    .safeAreaInset(edge: .bottom) {
                        CurrentAudioPanel()
                            .frame(maxWidth: .infinity, maxHeight: kCurrentAudioPanelHeight)
                            .background(
                                VisualEffectView(
                                    effect: UIBlurEffect(style: .regular)
                                )
                            )
                            .onTapGesture {
                                windowRepository.isShowingPlayerSheet = true
                            }
                    }
            }
            .navigationTitle(NSLocalizedString("navbar_library", comment: ""))
        }
    }
}

struct AlbumGridView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumGridView()
    }
}
