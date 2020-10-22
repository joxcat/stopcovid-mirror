// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  GesturesCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class GesturesCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        if #available(iOS 13.0, *) {
            let navController: UINavigationController = UINavigationController(rootViewController: OnboardingGesturesController(isOpenedFromOnboarding: false))
            let modalContainer: UIViewController = ModalContainerViewController.controller(navController, isFullScreen: true)
            presentingController?.present(modalContainer, animated: true, completion: nil)
        } else {
            let navigationController: UIViewController = UINavigationController(rootViewController: OnboardingGesturesController(isOpenedFromOnboarding: false))
            presentingController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
}
