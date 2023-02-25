//
//  LibrarySidebarView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/10.
//

import SwiftUI

struct LibrarySidebarView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance
    @Binding var category: SidebarCategory

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Image(systemName: "rectangle.stack.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.accentColor)
                Text(NSLocalizedString("sidebar_album", comment: ""))
                Spacer()
            }
            .frame(height: 14)
            .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .background(
                (category == .allAlbum ? Color.secondary.opacity(0.35) : Color.clear)
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onTapGesture {
                category = .allAlbum
                libraryRepository.currentAlbum = nil
                libraryRepository.currentPlaylist = nil
            }
        }
        .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }
}

struct LibrarySidebarView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
