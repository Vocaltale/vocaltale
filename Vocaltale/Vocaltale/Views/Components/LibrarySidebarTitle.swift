//
//  LibrarySidebarTitle.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/29.
//

import SwiftUI

struct LibrarySidebarTitle: View {
    @State private var isAddLibraryOpened = false

    var body: some View {
        HStack {
            Text(NSLocalizedString("sidebar_library", comment: ""))
                .font(.subheadline)
                .foregroundColor(NSColor.disabledControlTextColor.color)
                .bold()
                .layoutPriority(1)  // prevent ellipsis
            Spacer().frame(maxWidth: .infinity)  // fill in the gap
            //            Button {
            //                isAddLibraryOpened.toggle()
            //            } label: {
            //                Image(systemName: "plus")
            //                    .foregroundColor(.accentColor)
            //            }
            //            .buttonStyle(.borderless)
            //            .popover(isPresented: $isAddLibraryOpened, arrowEdge: .bottom) {
            //                VStack(alignment: .leading) {
            //                    Button {
            //                        LibraryService.instance.createLibrary()
            //                    } label: {
            //                        Text(NSLocalizedString("sidebar_create_library", comment: ""))
            //                    }
            //                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
            //                    .buttonStyle(.borderless)
            //                    .frame(alignment: .leading)
            //                    Spacer().frame(height: 6)
            //                    Button {
            //                        LibraryService.instance.openLibrary()
            //                    } label: {
            //                        Text(NSLocalizedString("sidebar_open_library", comment: ""))
            //                    }
            //                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
            //                    .buttonStyle(.borderless)
            //                    .frame(alignment: .leading)
            //                }
            //                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            //            }
        }
    }
}

struct LibrarySidebarTitle_Previews: PreviewProvider {
    static var previews: some View {
        LibrarySidebarTitle()
    }
}
