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
    @Published var playlistPath = NavigationPath()
    @Published var libraryPath = NavigationPath()
    @Published var isShowingPlayerSheet = false

    func attachGeometryReader(_ view: some View) -> some View {
        GeometryReader { geometry in
            view.onAppear {
                self.setGeometry(geometry)
            }
            .onChange(of: geometry) { newValue in
                self.setGeometry(newValue)
            }
        }
    }

    private func setGeometry(_ newValue: GeometryProxy) {
        if let geometry, geometry.isInvalid {
            if !newValue.isInvalid {
                debugPrint(#function, newValue.size, newValue.safeAreaInsets)
                self.geometry = newValue
            }
        } else {
            debugPrint(#function, newValue.size, newValue.safeAreaInsets)
            self.geometry = newValue
        }
    }
#endif
#if os(OSX)
    @Published var isShowingProgressModal = false
    @Published var isChildDragging = false
    @Published var isShowingAddPlaylistModel = false
#endif

}
