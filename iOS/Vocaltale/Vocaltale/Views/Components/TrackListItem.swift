//
//  TrackListItem.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

private struct TrackContextMenuPreview: View {
    let item: PlaylistItem

    var body: some View {
        VStack {
            Text(item.track.displayName)
                .font(.system(Font.TextStyle.caption))
                .bold()
                .lineLimit(2)
        }
    }
}

private struct TrackContextMenu: View {
    let item: PlaylistItem
    let playlist: Playlist?

    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @ObservedObject private var windowRepository = WindowRepository.instance

    var body: some View {
        TrackContextMenuPreview(item: item)
        Divider()
        Menu("playlist.add_track") {
            if !libraryRepository.playlists.isEmpty {
                Divider()
                ForEach(libraryRepository.playlists, id: \.id) { playlist in
                    Button {
                        libraryRepository.add(track: item.track, to: playlist)
                    } label: {
                        Label(playlist.name, image: "plus")
                    }
                }
            }
        }
        if let playlist {
            Divider()
            Button {
                if let playlistTrack = item.playlistTrack {
                    libraryRepository.delete(playlistTrack, from: playlist) {}
                }
            } label: {
                Label(NSLocalizedString("playlist.remove_track", comment: ""), image: "trash.fill")
            }
        }
    }
}

struct TrackListItem: View {
    let item: PlaylistItem
    let order: Int
    let playlist: Playlist?

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
            .appending(path: item.track.albumID)
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
                .frame(maxWidth: 24, maxHeight: 48)
            }
            if options.contains(.track) {
                Text(order.formatted())
                    .frame(width: 36, alignment: .leading)
            }
            if options.contains(.name) {
                VStack(alignment: .leading) {
                    Text(item.track.displayName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Text(item.track.displayArtist)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if options.contains(.duration) {
                Text(
                    Duration.seconds(item.track.duration).formatted(
                        .time(pattern: .minuteSecond(padMinuteToLength: 2))
                    )
                )
            }
        }
        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        .background(
            (selected ? Color.accentColor.opacity(0.5) : Color.clear)
                .contentShape(RoundedRectangle(cornerRadius: 6.0))
        )
        .clipShape(RoundedRectangle(cornerRadius: 6.0))
        .onTapGesture {
            onClick()
        }
        .contextMenu {
            TrackContextMenu(item: item, playlist: playlist)
        }
    }

}
