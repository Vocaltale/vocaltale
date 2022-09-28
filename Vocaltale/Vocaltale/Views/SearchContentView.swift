//
//  SearchContentView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/15.
//

import SwiftUI

struct SearchContentView: AlbumCardListViewMixins, View {
    @ObservedObject internal var libraryRepository = LibraryRepository.instance
    @State private var selectedAlbumID: String?
    @State private var selectedTrack: Track?
    @State internal var size: CGSize = .zero

    @State internal var albums: [Album] = []
    @State private var tracks: [Track] = []

    var body: some View {
        VStack {
            if !libraryRepository.searchResults.isEmpty {
                searchContentView
            } else {
                EmptyView()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .onChange(of: libraryRepository.searchResults) { results in
            albums = results[.albums] as? [Album] ?? []
            tracks = results[.tracks] as? [Track] ?? []
        }
        .onAppear {
            albums = libraryRepository.searchResults[.albums] as? [Album] ?? []
            tracks = libraryRepository.searchResults[.tracks] as? [Track] ?? []
        }
    }

    private var searchContentView: some View {
        GeometryReader { geometry in
            ScrollView {
                if libraryRepository.searchResults.keys.contains(.albums) {
                    HStack {
                        Text(NSLocalizedString("sidebar_album", comment: ""))
                            .font(Font.title2)
                            .bold()
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, kAlbumListSpacing + 12)
                    .frame(maxWidth: .infinity)
                    albumContentView
                }
                if libraryRepository.searchResults.keys.contains(.tracks) {
                    HStack {
                        Text(NSLocalizedString("sidebar_track", comment: ""))
                            .font(Font.title2)
                            .bold()
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, kAlbumListSpacing + 12)
                    .frame(maxWidth: .infinity)
                    trackContentView
                }
            }
            .onTapGesture {
                selectedAlbumID = nil
                selectedTrack = nil
            }
            .onChange(of: geometry.size) { value in
                size = value
            }
            .onAppear {
                size = geometry.size
            }
        }
    }

    private var trackContentView: some View {
        LazyVStack {
            ForEach(tracks, id: \.id) { track in
                TrackListItem(track: track, options: [
                    .coverArt,
                    .name,
                    .duration
                ], selected: selectedTrack == track) {
                    if let selectedTrack,
                       selectedTrack.uuid == track.uuid {
                        libraryRepository.currentAlbum = libraryRepository.album(of: track.albumID)
                    } else {
                        selectedAlbumID = nil
                        selectedTrack = track
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, kAlbumListSpacing + 12)
    }

    internal var albumContentView: some View {
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
                    .padding(
                        EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                    )
                    .onTapGesture {
                        if selectedAlbumID == album.uuid {
                            libraryRepository.currentAlbum = album
                        } else {
                            selectedTrack = nil
                            selectedAlbumID = album.uuid
                        }
                    }
                    .background(
                        (selectedAlbumID == album.uuid ? Color.accentColor.opacity(0.5) : Color.clear)
                            .contentShape(RoundedRectangle(cornerRadius: 8.0))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                    .contextMenu {
                        AlbumContextMenu(album: album)
                    }
            }
            ForEach(0..<(albumColumn - (albums.count % albumColumn)), id: \.self) { _ in
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, kAlbumListSpacing + 12)
    }
}

struct SearchContentView_Previews: PreviewProvider {
    static var previews: some View {
        SearchContentView()
    }
}
