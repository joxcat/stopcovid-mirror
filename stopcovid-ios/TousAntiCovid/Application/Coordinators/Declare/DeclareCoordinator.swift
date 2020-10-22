// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeclareCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class DeclareCoordinator: Coordinator {

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
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: DeclareController(didTouchFlash: { [weak self] in
            self?.showFlash()
        }, didTouchTap: { [weak self] in
            self?.showTap()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
    private func showFlash() {
        let flashCodeCoordinator: FlashCodeCoordinator = FlashCodeCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: flashCodeCoordinator)
    }
    
    private func showTap() {
        let enterCodeCoordinator: EnterCodeCoordinator = EnterCodeCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: enterCodeCoordinator)
    }
    
}
