//
//  AlbumView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

struct AlbumView: View {
    let album: Album?

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @State private var artworkSize: CGSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)

    private var artworkURL: URL? {
        if let uuid = album?.uuid {
            return libraryRepository.currentLibraryURL?.appending(path: "metadata")
                .appending(path: uuid)
                .appending(path: "artwork")
        }

        return nil
    }

    var body: some View {
        Group {
            VStack(spacing: 16.0) {
                Group {
                    if let artworkURL,
                       let image = Image(url: artworkURL) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ZStack {
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(.secondary.opacity(0.5))
                                    .aspectRatio(1, contentMode: .fit)
                                    .onChange(of: geometry.size) { size in
                                        artworkSize = size
                                    }
                                    .onAppear {
                                        debugPrint(geometry.size)
                                        artworkSize = geometry.size
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                            Image(systemName: "music.note")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .padding(.all, 16)
                                .frame(maxWidth: artworkSize.width, maxHeight: artworkSize.width)
                        }
                    }
                }
                .shadow(radius: 4.0)
                Text(album?.displayName ?? NSLocalizedString("album_unknown", comment: ""))
                    .font(Font.headline)
                    .bold()
                Text(
                    album == nil ?
                        NSLocalizedString("artist_unknown", comment: "") :
                        libraryRepository.artistNames(of: album!).joined(separator: ", ")
                )
                .lineLimit(3)
                .font(Font.subheadline)
                .foregroundColor(.accentColor)
            }
        }
    }
}
