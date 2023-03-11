//
//  GeometryProxy+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import Foundation
import SwiftUI

extension GeometryProxy: Equatable {
    public static func == (lhs: GeometryProxy, rhs: GeometryProxy) -> Bool {
        return lhs.size == rhs.size && lhs.safeAreaInsets == rhs.safeAreaInsets
    }

    public var isInvalid: Bool {
        self.size == .zero || self.safeAreaInsets == EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
}
