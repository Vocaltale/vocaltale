//
//  ArtworkIcon.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/4.
//

import SwiftUI

struct ArtworkIcon: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.secondary)
                .aspectRatio(1, contentMode: .fit)
            Image(systemName: "music.note")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .padding(.all, 16)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct ArtworkIcon_Previews: PreviewProvider {
    static var previews: some View {
        ArtworkIcon()
    }
}
