//
//  SearchGridView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/3.
//

import SwiftUI

struct SearchGridView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var selectedTrack: Track?

    @State internal var albums: [Album] = []
    var body: some View {
        NavigationStack {
            ScrollView {
                TextField("tabview_search_keyword_placeholder", text: $libraryRepository.keyword)
                    .lineLimit(1)
                    .padding(.all, 16.0)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: libraryRepository.keyword) { value in
                        LibraryService.instance.search(for: value)
                    }
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: kCurrentAudioPanelHeight, maximum: .infinity)),
                        GridItem(.flexible(minimum: kCurrentAudioPanelHeight, maximum: .infinity))
                    ],
                    content: {
                        ForEach(albums, id: \.id) { album in
                            NavigationLink {
                                if let album = libraryRepository.currentAlbum {
                                    AlbumDetailView(album: album)
                                }
                            } label: {
                                AlbumCardView(album: album)
                                    .foregroundColor(Color.primary)
                                    .frame(alignment: .center)
                                    .padding(
                                        EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                            }.simultaneousGesture(
                                TapGesture().onEnded({ _ in
                                    libraryRepository.currentAlbum = album
                                })
                            )
                        }
                        .onChange(of: libraryRepository.searchResults) { value in
                            if let results = value[.albums] as? [Album] {
                                albums = results
                            }
                        }
                        .onAppear {
                            if let results = libraryRepository.searchResults[.albums] as? [Album] {
                                albums = results
                            }
                        }
                        if (albums.count % 2) == 1 {
                            Spacer()
                        }
                        Spacer()
                            .frame(width: kCurrentAudioPanelHeight, height: kCurrentAudioPanelHeight)
                        Spacer()
                            .frame(width: kCurrentAudioPanelHeight, height: kCurrentAudioPanelHeight)
                    }
                )
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
            .navigationTitle(NSLocalizedString("navbar_search", comment: ""))
        }
        .onChange(of: libraryRepository.searchResults) { results in
            albums = results[.albums] as? [Album] ?? []
        }
    }
}

struct SearchGridView_Previews: PreviewProvider {
    static var previews: some View {
        SearchGridView()
    }
}
