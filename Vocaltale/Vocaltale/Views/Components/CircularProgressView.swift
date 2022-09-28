//
//  CircularProgressView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/21.
//

import SwiftUI

struct CircularProgressView: View {
    var progress: Double
    var width: CGFloat
    let foreground: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.5),
                    lineWidth: width
                )
            Circle()
                .trim(from: 0, to: max(progress, 0.05))
                .stroke(
                    foreground,
                    style: StrokeStyle(
                        lineWidth: width,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.default, value: progress)
        }
    }
}
