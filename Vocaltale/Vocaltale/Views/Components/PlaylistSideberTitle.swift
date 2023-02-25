//
//  PlaylistSideberTitle.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/25.
//

import SwiftUI

struct PlaylistSideberTitle: View {
    var body: some View {
        HStack {
            Text(NSLocalizedString("sidebar_playlist", comment: ""))
                .font(.subheadline)
                .foregroundColor(NSColor.disabledControlTextColor.color)
                .bold()

            Spacer().frame(maxWidth: .infinity)  // fill in the gap
        }
    }
}

struct PlaylistSideberTitle_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistSideberTitle()
    }
}
