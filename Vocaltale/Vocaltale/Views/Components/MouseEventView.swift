//
//  ClickableView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/15.
//

import SwiftUI

protocol ContextType {
    var payload: [String: Any] { get set }
}

protocol ContextView<T>: View {
    associatedtype T: ContextType
    var context: Binding<Self.T> { get set }

    init(context: Binding<T>)
}

struct MouseEventView<T: ContextType, V: ContextView<T>>: NSViewRepresentable {
    typealias NSViewType = MouseEventNSHostingView

    @Binding var context: T
    let onMouseDown: (NSEvent) -> Void
    let onRightMouseDown: (NSEvent, CGRect, CGPoint) -> Void

    func updateNSView(_ nsView: NSViewType<T, V>, context: Context) {
        nsView.context = self.$context
    }

    func makeNSView(context: Context) -> NSViewType<T, V> {
        MouseEventNSHostingView(
            self.$context,
            onMouseDown: onMouseDown,
            onRightMouseDown: onRightMouseDown
        )
    }
}
//
// fileprivate extension NSView {
//    var bitmapImage: NSImage? {
//        get {
//            guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
//                return nil
//            }
//            cacheDisplay(in: bounds, to: rep)
//            guard let cgImage = rep.cgImage else {
//                return nil
//            }
//            return NSImage(cgImage: cgImage, size: bounds.size)
//        }
//    }
// }
//
// fileprivate class NoInsetHostingView<V>: NSHostingView<V> where V: View {
//    override var safeAreaInsets: NSEdgeInsets {
//        return .init()
//    }
// }

class MouseEventNSHostingView<T: ContextType, V: ContextView<T>>: NSHostingView<V> {
    let onMouseDown: (NSEvent) -> Void
    let onRightMouseDown: (NSEvent, CGRect, CGPoint) -> Void

    var context: Binding<V.T>

    init(
        _ context: Binding<V.T>,
        onMouseDown: @escaping (NSEvent) -> Void,
        onRightMouseDown: @escaping (NSEvent, CGRect, CGPoint) -> Void
    ) {
        self.context = context
        self.onMouseDown = onMouseDown
        self.onRightMouseDown = onRightMouseDown

        super.init(rootView: V(context: context))

        registerForDraggedTypes([
            .string
        ])
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor required init(rootView: V) {
        self.context = rootView.context

        self.onMouseDown = { _ in }
        self.onRightMouseDown = { _, _, _ in }

        super.init(rootView: rootView)
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown(event)
    }

    override func rightMouseDown(with event: NSEvent) {
        //        frame.origin
        onRightMouseDown(event, frame, superview!.convert(frame.origin, to: nil))
    }
}
