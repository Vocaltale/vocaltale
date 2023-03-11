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
        NavigationStack(path: $windowRepository.playlistPath) {
            ScrollView {
                LazyVStack(spacing: 4) {
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
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                Spacer()
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
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
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
            .navigationTitle(NSLocalizedString("navbar_playlist", comment: ""))
        }
    }
}

struct PlaylistListView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistListView()
    }
}
