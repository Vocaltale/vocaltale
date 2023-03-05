//
//  ContentView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isSideBarOpened = false
    @State private var isAddLibraryOpened = false
    @State private var isAddPlaylistOpened = false

    @State var category: SidebarCategory = .none

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance

    //    private var subtitle: String {
    //        "\(libraryRepository.currentLibraryURL?.lastPathComponent ?? "")"
    //    }

    var body: some View {
        NavigationSplitView {
            ScrollView {
                VStackLayout(spacing: 12.0) {
                    SearchSidebarView(
                        category: $category
                    )
                    .frame(maxWidth: .infinity)
                    Section {
                        LibrarySidebarView(
                            category: $category
                        )
                    } header: {
                        LibrarySidebarTitle()
                    }
                    Section {
                        PlaylistSidebarView(
                            category: $category
                        )
                    } header: {
                        PlaylistSideberTitle()
                    }
                }
                .padding(.all, 12.0)
            }
            .onTapGesture {
                category = .none
                libraryRepository.currentAlbum = nil
                libraryRepository.currentPlaylist = nil
            }
            .navigationSplitViewColumnWidth(min: 192, ideal: 256, max: 320)
        } detail: {
            ZStack {
                switch category {
                case .search:
                    SearchContentView()
                case .album:
                    if let selectedAlbumID = libraryRepository.currentAlbumID,
                       let album = libraryRepository.albums.first(where: { a in
                        a.uuid == selectedAlbumID
                       }) {
                        AlbumContentView(album: album)
                    } else {
                        Spacer()
                    }
                case .allAlbum:
                    AlbumListContentView()
                case .playlist:
                    PlaylistContentView()
                default:
                    Spacer()
                }
            }
            .safeAreaInset(edge: .top) {
                AudioPlayerPanel()
                    .edgesIgnoringSafeArea(.all)
                    .background(
                        VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                    )
            }
            .edgesIgnoringSafeArea(.all)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(.hidden, for: .automatic, .windowToolbar)
        .sheet(isPresented: $windowRepository.isShowingProgressModal) {
            ProgressModalView()
                .padding(.all, 16)
        }
        .sheet(isPresented: $windowRepository.isShowingAddPlaylistModel) {
            AddPlaylistModelView()
                .padding(.all, 16)
        }
        .onChange(of: category) { value in
            // it is a measure to reset sidebar category to all album
            if value == .none {
                category = .allAlbum
            }
        }
        .onChange(of: libraryRepository.currentAlbumID) { value in
            if value != nil {
                category = .album
            } else {
                category = .allAlbum
            }
        }
        .onChange(of: libraryRepository.event.state) { value in
            windowRepository.isShowingProgressModal = value == .loading
        }
        .overlay {
            if windowRepository.isChildDragging {
                Rectangle()
                    .foregroundColor(.clear)
            } else {
                Rectangle()
                    .foregroundColor(.clear)
                    .onDrop(
                        of: [UTType.directory, UTType.audio],
                        isTargeted: nil
                    ) { (providers, _) in
                        providers.forEach { provider in
                            if let type = provider.registeredContentTypes.first {
                                provider.loadItem(forTypeIdentifier: type.identifier) { result, error in
                                    if error != nil {
                                        return
                                    }

                                    if let url = result as? URL {
                                        print(url)

                                        LibraryService.instance.importFiles(from: url)
                                    }
                                }
                            }
                        }

                        return true
                    }
            }
        }
        .onAppear {
            if let url = libraryRepository.ubiquityPublicDocumentURL?.appending(
                path: kDefaultProjectFilename
            ) {
                LibraryService.instance.openLibrary(from: url)

                if libraryRepository.currentAlbumID != nil {
                    category = .album
                } else {
                    category = .allAlbum
                    libraryRepository.currentAlbum = nil
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
