//
//  AlbumCardView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/21.
//

import SwiftUI

struct AlbumCardView: View {
    let album: Album

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private var artworkURL: URL? {
        return libraryRepository.currentLibraryURL?.appending(path: "metadata")
            .appending(path: album.uuid)
            .appending(path: "artwork")
    }

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if let artworkURL,
                   let image = Image(url: artworkURL) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.5))
                            .aspectRatio(1, contentMode: .fit)
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6.0))
            .shadow(radius: 4.0)
            Text(album.displayName)
                .font(.system(Font.TextStyle.caption))
                .bold()
                .lineLimit(2)
            Text(libraryRepository.artistNames(of: album).joined(separator: ", "))
                .font(.system(Font.TextStyle.caption))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}
