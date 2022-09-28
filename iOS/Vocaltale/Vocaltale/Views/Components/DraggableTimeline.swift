//
//  DraggableTimeline.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI
import AVFoundation

struct DraggableTimeline: View {
    @ObservedObject private var audioPlayerRepository = AudioPlaybackRepository.instance
    @State private var size: CGSize?
    @State private var progress: Double = 0.0
    @State private var isEditing = false
    @Binding var progressOverride: Double?

    private var emptyTimeline: some View {
        Rectangle()
            .foregroundColor(Color(uiColor: UIColor.secondarySystemBackground).opacity(0.75))
    }

    private var draggableTimeline: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(Color(uiColor: UIColor.secondarySystemBackground).opacity(0.75))
            if progressOverride != nil || !audioPlayerRepository.isPlaying {
                Rectangle()
                    .frame(
                        width: max(0, progressOverride ?? audioPlayerRepository.currentProgress) * (size?.width ?? 0),
                        alignment: .leading
                    )
                    .foregroundColor(.accentColor.opacity(0.75))
            } else {
                Rectangle()
                    .frame(
                        width: max(0, audioPlayerRepository.progress) * (size?.width ?? 0),
                        alignment: .leading
                    )
                    .foregroundColor(.accentColor.opacity(0.75))
            }
        }
        .onChange(of: audioPlayerRepository.progress) { _ in
            if !isEditing && progressOverride != nil {
                progressOverride = nil
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    isEditing = true
                    if let size {
                        progress = gesture.location.x / size.width
                        progressOverride = progress
                    }
                }
                .onEnded { gesture in
                    if let size {
                        let progress = gesture.location.x / size.width
                        self.progress = progress
                        progressOverride = progress
                        isEditing = false

                        audioPlayerRepository.seek(progress)
                    }
                }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if audioPlayerRepository.currentTrack != nil || audioPlayerRepository.isPlaying {
                    draggableTimeline
                } else {
                    emptyTimeline
                }
            }
            .onChange(of: geometry.size) { value in
                size = value
            }
            .onAppear {
                size = geometry.size
            }
        }
    }
}
