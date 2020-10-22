// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UITabBarController+Appearance.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UITabBarController {
    
    func configureTabBarAppearance() {
        
        if #available(iOS 13.0, *) {
            let normalAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.medium(size: 10.0), .foregroundColor: UIColor.lightGray]
            let selectedAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.medium(size: 10.0), .foregroundColor: Asset.Colors.tint.color]
            let tabbarAppearence: UITabBarAppearance = UITabBarAppearance()
            tabbarAppearence.stackedLayoutAppearance.normal.iconColor = .lightGray
            tabbarAppearence.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
            tabbarAppearence.stackedLayoutAppearance.selected.iconColor = Asset.Colors.tint.color
            tabbarAppearence.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
            tabBar.standardAppearance = tabbarAppearence
        } else {
            UITabBar.appearance().tintColor = Asset.Colors.tint.color
        }
        
    }
    
}
