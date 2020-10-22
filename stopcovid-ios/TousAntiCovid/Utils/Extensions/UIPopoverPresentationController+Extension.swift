// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIPopoverPresentationController+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/05/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIPopoverPresentationController {
    
    func setSourceButton(_ button: UIButton) {
        sourceView = button
        var rect: CGRect = button.bounds
        rect.origin.y = rect.maxY
        rect.origin.x = rect.midX
        rect.size = .zero
        sourceRect = rect
        permittedArrowDirections = .up
    }
    
}
