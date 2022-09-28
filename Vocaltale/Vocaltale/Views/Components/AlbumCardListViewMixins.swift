//
//  AlbumCardListView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/21.
//

import SwiftUI

internal let kAlbumListSpacing: CGFloat = 16

protocol AlbumCardListViewMixins {
    var albums: [Album] { get }
    var size: CGSize { get }
}

extension AlbumCardListViewMixins {
    internal var albumColumn: Int {
        let width = size.width

        let minWidth = 224.0
        let maxWidth = 272.0

        let minRatio = width / minWidth
        let maxRatio = width / maxWidth
        let columns = round((maxRatio + minRatio) / 2.0)

        return max(1, Int(columns))
    }
}
