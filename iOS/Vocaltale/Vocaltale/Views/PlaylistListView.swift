//
//  PlaylistListView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import SwiftUI

struct PlaylistListView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance

    var body: some View {
        NavigationStack(path: $windowRepository.navigationPath) {
            ScrollView {
                ForEach(libraryRepository.playlists, id: \.id) { playlist in
                    NavigationLink(value: playlist) {
                        HStack {
                            Text(playlist.name)
                            Spacer()
                        }.padding(.all, 4.0)
                    }.simultaneousGesture(
                        TapGesture().onEnded({ _ in
                            libraryRepository.currentAlbum = nil
                            libraryRepository.currentPlaylist = playlist
                        })
                    )
                }
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .navigationTitle(NSLocalizedString("navbar_playlist", comment: ""))
        }
    }
}

struct PlaylistListView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistListView()
    }
}
