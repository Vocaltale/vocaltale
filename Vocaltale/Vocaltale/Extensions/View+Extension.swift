//
//  View+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/28.
//

import Foundation
import SwiftUI

extension View {
    func draggingWindow() -> some View {
        WindowDraggable().overlay(self)
    }
}

struct WindowDraggable: View {
    var body: some View {
        Color.clear.contentShape(Rectangle()).overlay(WindowDraggableViewRepresentable())
    }
}

private struct WindowDraggableViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return WindowDraggableView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class WindowDraggableView: NSView {
    override public func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
