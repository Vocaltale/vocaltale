//
//  TrackView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/3.
//

import SwiftUI

struct TrackView: View {
    let track: Track?
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
        VStack(spacing: 16.0) {
            Group {
                if let artworkURL,
                   let image = Image(url: artworkURL) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ArtworkIcon()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4.0))
            .shadow(radius: 4.0)
            Text(track?.displayName ?? NSLocalizedString("track_unknown", comment: ""))
                .font(Font.title)
                .bold()
            Text(track?.displayArtist ?? NSLocalizedString("artist_unknown", comment: ""))
                .font(Font.title2)
                .foregroundColor(.accentColor)
        }
    }
}
