//
//  NavigationPath+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/21.
//

import SwiftUI

extension NavigationPath {
    mutating func setAlbum(_ album: Album) {
        if count > 0 {
            removeLast()
        }

        append(album)
    }
}
