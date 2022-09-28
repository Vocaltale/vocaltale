//
//  TrackListItem.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/9.
//

import SwiftUI

private struct TrackContextMenuPreview: View {
    let track: Track

    var body: some View {
        VStack {
            Text(track.displayName)
                .font(.system(Font.TextStyle.caption))
                .bold()
                .lineLimit(2)
        }
    }
}
private struct TrackContextMenu: View {
    let track: Track

    @State private var keyword: String = ""

    var body: some View {
        TrackContextMenuPreview(track: track)
        Divider()
        Menu("Add to Playlist") {
            Button {

            } label: {
                Label("Add Playlist", image: "plus")
            }
            Divider()
        }
    }
}

struct TrackListItem: View {
    let track: Track

    enum DisplayOption {
        case track
        case coverArt
        case name
        case duration
    }

    var options: Set<DisplayOption> = [
        .track,
        .name,
        .duration
    ]

    let selected: Bool

    let onClick: (() -> Void)

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    private var artworkURL: URL? {
        return libraryRepository.currentLibraryURL?.appending(path: "metadata")
            .appending(path: track.albumID)
            .appending(path: "artwork")
    }

    var body: some View {
        HStack {
            if options.contains(.coverArt) {
                Group {
                    if let artworkURL = artworkURL,
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
                                .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(maxWidth: 48, maxHeight: 48)
            }
            if options.contains(.track) {
                Text(track.track.formatted())
                    .frame(width: 64, alignment: .leading)
            }
            if options.contains(.name) {
                VStack(alignment: .leading) {
                    Text(track.displayName)
                        .font(.body)
                        .bold()
                        .lineLimit(1)
                    Text(track.displayArtist)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if options.contains(.duration) {
                Text(
                    Duration.seconds(track.duration).formatted(
                        .time(pattern: .minuteSecond(padMinuteToLength: 2))
                    )
                )
            }
        }
        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        .background(
            (selected ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear)
                .contentShape(RoundedRectangle(cornerRadius: 4.0))
        )
        .clipShape(RoundedRectangle(cornerRadius: 4.0))
        .onTapGesture {
            onClick()
        }
        //        .contextMenu {
        //            TrackContextMenu(track: track)
        //        }
    }
}
