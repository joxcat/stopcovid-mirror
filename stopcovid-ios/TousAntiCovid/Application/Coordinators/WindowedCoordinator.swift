// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WindowedCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol WindowedCoordinator: Coordinator {

    var window: UIWindow! { get set }
    
    func createWindow(for controller: UIViewController)
    
}

extension WindowedCoordinator {
    
    func createWindow(for controller: UIViewController) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = controller
        window?.accessibilityViewIsModal = true
        window?.alpha = 0.0
        window?.makeKeyAndVisible()
    }
    
}
