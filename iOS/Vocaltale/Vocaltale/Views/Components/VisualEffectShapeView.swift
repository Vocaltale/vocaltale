//
//  VisualEffectShapeView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/2/3.
//

import SwiftUI

struct VisualEffectShapeView: ShapeStyle {
    let effect: UIVisualEffect

    var body: some View {
        VisualEffectView(effect: effect)
    }
}
