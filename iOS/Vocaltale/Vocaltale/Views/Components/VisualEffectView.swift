//
//  VisualEffectView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/2.
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: effect)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}
