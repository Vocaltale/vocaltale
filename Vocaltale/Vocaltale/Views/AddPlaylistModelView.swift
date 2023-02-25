//
//  AddPlaylistModelView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import SwiftUI

struct AddPlaylistModelView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance

    @State private var keyword: String = ""
    @State private var playlistName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            TextField("playlist.create_name", text: $playlistName)
            Button {
                libraryRepository.createPlaylist(playlistName)
                windowRepository.isShowingAddPlaylistModel = false
            } label: {
                Label(NSLocalizedString("playlist.add", comment: ""), systemImage: "plus")
            }
        }
        .frame(width: 256)
    }
}

struct AddPlaylistModelView_Previews: PreviewProvider {
    static var previews: some View {
        AddPlaylistModelView()
    }
}
