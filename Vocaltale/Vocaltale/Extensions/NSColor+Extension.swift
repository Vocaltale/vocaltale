//
//  NSColor+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import AppKit
import Foundation
import SwiftUI

extension NSColor {
    public var color: Color {
        return Color.init(nsColor: self)
    }
}
