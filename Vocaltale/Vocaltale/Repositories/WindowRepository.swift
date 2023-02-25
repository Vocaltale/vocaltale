//
//  DisplayRepository.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/11.
//

import Foundation
import SwiftUI

class WindowRepository: ObservableObject {
    static let instance = WindowRepository()

    @Published var geometry: GeometryProxy?
#if os(iOS)
    @Published var selectedTabTag = TabCategory.library
    @Published var navigationPath = NavigationPath()
    @Published var isShowingPlayerSheet = false
#endif
#if os(OSX)
    @Published var isShowingProgressModal = false
    @Published var isChildDragging = false
    @Published var isShowingAddPlaylistModel = false
#endif
}
