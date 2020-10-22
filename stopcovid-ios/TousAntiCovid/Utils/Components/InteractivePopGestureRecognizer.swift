// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InteractivePopGestureRecognizer.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 15/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class InteractivePopGestureRecognizer: NSObject, UIGestureRecognizerDelegate {

    var navigationController: UINavigationController

    init(controller: UINavigationController) {
        self.navigationController = controller
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController.viewControllers.count > 1
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // This is to prevent tableView to be scrolled when the navigation controller swipe gesture is used.
        return !"\(type(of: otherGestureRecognizer))".hasPrefix("UIScrollViewPan")
    }
    
}
