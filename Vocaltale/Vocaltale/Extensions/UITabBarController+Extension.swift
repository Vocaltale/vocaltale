//
//  UITabBarController+Extension.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2023/1/30.
//

import Foundation
import UIKit

extension UITabBarController {
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        tabBar.standardAppearance = appearance
    }
}
