//
//  ContextMenuButton.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/15.
//

import SwiftUI

struct ContextMenuButton: View {
    let localizedStringKey: String
    let action: () -> Void

    @State private var isHover = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(NSLocalizedString(localizedStringKey, comment: ""))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderless)
        .background(Color.accentColor.opacity(isHover ? 0.5 : 0))
        .onHover { value in
            isHover = value
        }
    }
}
