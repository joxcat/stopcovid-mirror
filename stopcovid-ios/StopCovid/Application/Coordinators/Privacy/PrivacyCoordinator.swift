// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PrivacyCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit

final class PrivacyCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var currentController: UIViewController?
    
    init(navigationController: UINavigationController?, parent: Coordinator) {
        self.navigationController = navigationController
        self.parent = parent
        start()
    }
    
    private func start() {
        let controller: UIViewController = CVNavigationChildController.controller(OnboardingPrivacyController(isOpenedFromOnboarding: false, deinitBlock:  { [weak self] in
            self?.didDeinit()
        }))
        self.currentController = controller
        controller.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
}
