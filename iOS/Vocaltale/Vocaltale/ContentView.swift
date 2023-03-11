//
//  ContentView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/1/30.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $windowRepository.selectedTabTag) {
                AlbumGridView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tabItem {
                        Label(NSLocalizedString("tabview_library", comment: ""), systemImage: "music.note")
                    }
                    .tag(TabCategory.library)
                    .toolbarBackground(
                        VisualEffectShapeView(effect: UIBlurEffect(style: .regular)),
                        for: .tabBar
                    )
                PlaylistListView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tabItem {
                        Label(NSLocalizedString("tabview_playlist", comment: ""), systemImage: "music.note.list")
                    }
                    .tag(TabCategory.playlist)
                    .toolbarBackground(
                        VisualEffectShapeView(effect: UIBlurEffect(style: .regular)),
                        for: .tabBar
                    )
                SearchGridView()
                    .tabItem {
                        Label(NSLocalizedString("tabview_search", comment: ""), systemImage: "magnifyingglass")
                    }
                    .tag(TabCategory.search)
                    .toolbarBackground(
                        VisualEffectShapeView(effect: UIBlurEffect(style: .regular)),
                        for: .tabBar
                    )
            }
        }
        .sheet(
            isPresented: $windowRepository.isShowingPlayerSheet,
            onDismiss: {
                windowRepository.isShowingPlayerSheet = false
            },
            content: {
                PlayerControlView()
            }
        )
        .ignoresSafeArea(.all)
        .onAppear {
            if let url = libraryRepository.ubiquityPublicDocumentURL?.appending(
                path: kDefaultProjectFilename
            ) {
                DispatchQueue.global(qos: .background).sync {
                    LibraryService.instance.openLibrary(from: url)
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
