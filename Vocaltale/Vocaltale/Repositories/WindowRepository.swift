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
#endif
    @Published var isShowingModal = false
    @Published var isChildDragging = false
}
