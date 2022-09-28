//
//  AlbumContextMenu.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/18.
//

import SwiftUI

private struct AlbumContextMenuPreview: View {
    let album: Album

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private var artworkURL: URL? {
        libraryRepository.currentLibraryURL?.appending(path: "metadata")
            .appending(path: album.uuid)
            .appending(path: "artwork")
    }

    var body: some View {
        VStack {
            Text(album.displayName)
                .font(.system(Font.TextStyle.caption))
                .bold()
                .lineLimit(2)
        }
    }
}

struct AlbumContextMenu: View {
    let album: Album

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    var body: some View {
        AlbumContextMenuPreview(album: album)
        Divider()
        Button(NSLocalizedString("album_goto", comment: "")) {
            libraryRepository.currentAlbum = album
        }
        Button(NSLocalizedString("sidebar_album_delete", comment: "")) {
            LibraryService.instance.delete(album: album)
        }
    }
}
