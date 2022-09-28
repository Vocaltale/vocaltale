//
//  Image+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/11.
//

import SwiftUI

extension Image {
    init?(url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
#if os(OSX)
        guard let image = NSImage(data: data) else { return nil }

        self.init(nsImage: image)
#else
        guard let image = UIImage(data: data) else { return nil }

        self.init(uiImage: image)
#endif
    }
}
