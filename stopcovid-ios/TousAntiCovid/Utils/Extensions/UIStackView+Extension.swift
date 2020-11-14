// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIStackView+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/11/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIStackView {
    
    static var thresholdCategorySize: UIContentSizeCategory {
        switch Int(UIScreen.main.bounds.width) {
        case 0..<375:
            return .extraExtraExtraLarge
        default:
            return .accessibilityMedium
        }
    }
    
}
