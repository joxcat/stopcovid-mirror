// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIBarButtonItem+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 15/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIBarButtonItem {
    
    static func back(target: Any?, action: Selector?) -> UIBarButtonItem {
        let buttonItem: UIBarButtonItem = UIBarButtonItem(image: Asset.Images.chevron.image, style: .plain, target: target, action: action)
        buttonItem.isAccessibilityElement = true
        buttonItem.accessibilityLabel = "accessibility.back.label".localized
        return buttonItem
    }
    
}
