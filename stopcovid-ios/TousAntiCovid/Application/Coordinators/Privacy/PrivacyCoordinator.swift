// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PrivacyCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class PrivacyCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: OnboardingPrivacyController(isOpenedFromOnboarding: false, deinitBlock:  { [weak self] in
            self?.didDeinit()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
}