//
//  ProgressModalView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/21.
//

import SwiftUI

struct ProgressModalView: View {
    @ObservedObject private var libraryRepository = LibraryRepository.instance

    var body: some View {
        if libraryRepository.fileCount > 0 {
            ProgressView(
                String(
                    format: NSLocalizedString("modal_processing", comment: ""),
                    libraryRepository.fileCount,
                    libraryRepository.processedFileCount
                )
            )
            .frame(minWidth: 224, minHeight: 128, alignment: .center)
        } else if libraryRepository.isDownloading {
            CircularProgressView(
                progress: libraryRepository.downloadProgress,
                width: 6,
                foreground: .accentColor
            )
            .padding(.all, 36)
            .frame(minWidth: 128, minHeight: 128, alignment: .center)
        } else {
            ProgressView()
                .frame(minWidth: 128, minHeight: 128, alignment: .center)
        }
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressModalView()
    }
}
