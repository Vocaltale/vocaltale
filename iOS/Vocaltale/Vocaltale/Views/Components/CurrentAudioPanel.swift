//
//  CurrentAudioPanel.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

struct CurrentAudioPanel: View {
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @ObservedObject private var libraryRepository = LibraryRepository.instance

    @State private var progressOverride: Double?
    @State private var displayHover: Bool = false

    private var album: Album? {
        return audioPlayerRepository.currentAlbum
    }

    private var artworkURL: URL? {
        if let album {
            return libraryRepository.currentLibraryURL?.appending(path: "metadata")
                .appending(path: album.uuid)
                .appending(path: "artwork")
        }

        return nil
    }

    private var currentTime: String? {
        let progress = progressOverride ?? audioPlayerRepository.progress

        if let track = audioPlayerRepository.currentTrack {
            let seconds = Int64(progress * Double(track.duration))
            let duration = Duration(secondsComponent: seconds, attosecondsComponent: 0)

            return duration.formatted(.time(pattern: .minuteSecond))
        }

        return nil
    }

    private var totalTime: String? {
        if let track = audioPlayerRepository.currentTrack {
            let seconds = Int64(track.duration)
            let duration = Duration(secondsComponent: seconds, attosecondsComponent: 0)

            return duration.formatted(.time(pattern: .minuteSecond))
        }

        return nil
    }

    private var display: some View {
        HStack(spacing: .zero) {
            if let artworkURL,
               let image = Image(url: artworkURL) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: kCurrentAudioPanelHeight)
            } else {
                ZStack {
                    Rectangle()
                        .fill(.secondary.opacity(0.5))
                        .aspectRatio(1, contentMode: .fit)
                    Image(systemName: "music.note")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }
                .frame(width: kCurrentAudioPanelHeight, height: kCurrentAudioPanelHeight)
            }
            VStack(spacing: .zero) {
                VStack(alignment: .center) {
                    Text(
                        audioPlayerRepository.currentTrack?.displayName ?? NSLocalizedString(
                            "track_unknown",
                            comment: ""
                        )
                    )
                        .font(.system(Font.TextStyle.body))
                        .bold()
                        .lineLimit(1)
                    Text(
                        audioPlayerRepository.currentTrack?.displayArtist ?? NSLocalizedString(
                            "artist_unknown",
                            comment: ""
                        )
                    )
                        .font(.system(Font.TextStyle.caption))
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                }
                .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack(alignment: .bottom) {
                    Text(currentTime ?? "00:00")
                        .font(.system(Font.TextStyle.caption))
                        .foregroundColor(.secondary.opacity(0.75))
                        .lineLimit(1)
                    Spacer()
                    Text(totalTime ?? "00:00")
                        .font(.system(Font.TextStyle.caption))
                        .foregroundColor(.secondary.opacity(0.75))
                        .lineLimit(1)
                }
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 4, trailing: 12))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: 72)
    }

    var body: some View {
        display
    }
}

struct CurrentAudioPanel_Previews: PreviewProvider {
    static var previews: some View {
        CurrentAudioPanel()
    }
}
