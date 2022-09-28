//
//  AlbumView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/9.
//

import SwiftUI

struct AlbumView: View {
    let album: Album

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private var artworkURL: URL? {
        return libraryRepository.currentLibraryURL?.appending(path: "metadata")
            .appending(path: album.uuid)
            .appending(path: "artwork")
    }

    var body: some View {
        Group {
            HStack(alignment: .top, spacing: 16.0) {
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
                                .padding(.all, 16)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4.0)
                VStack(alignment: .leading) {
                    Text(album.displayName)
                        .font(Font.title)
                        .bold()
                    Text(libraryRepository.artistNames(of: album).joined(separator: ", "))
                        .font(Font.title2)
                        .foregroundColor(.secondary)
                    Spacer()
                    PlayNowButton()
                        .frame(maxHeight: 36)
                }
                Spacer()
            }
        }
        .padding(.all, 16.0)
        .frame(
            maxWidth: .infinity,
            maxHeight: 192,
            alignment: .topLeading
        )
    }
}
