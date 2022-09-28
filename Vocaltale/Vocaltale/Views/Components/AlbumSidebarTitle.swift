//
//  AlbumSidebarTitle.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/10.
//

import SwiftUI

struct AlbumSidebarTitle: View {
    var body: some View {
        HStack {
            Text(NSLocalizedString("sidebar_album", comment: ""))
                .font(.subheadline)
                .foregroundColor(NSColor.disabledControlTextColor.color)
                .bold()

            Spacer().frame(maxWidth: .infinity)  // fill in the gap
        }
    }
}

struct AlbumSidebarTitle_Previews: PreviewProvider {
    static var previews: some View {
        AlbumSidebarTitle()
    }
}
