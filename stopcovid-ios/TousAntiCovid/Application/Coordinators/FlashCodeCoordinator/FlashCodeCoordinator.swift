// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashCodeCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class FlashCodeCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var presentingController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        let controller: UIViewController = FlashCodeController.controller(didFlash: { [weak self] code in
            guard let code = code else { return }
            self?.showSymptomsOrigin(symptomsParams: SymptomsDeclarationParams(code: code))
        }) { [weak self] in
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true, completion: nil)
    }
    
    private func showSymptomsOrigin(symptomsParams: SymptomsDeclarationParams) {
        let symptomsOriginCoordinator: SymptomsOriginCoordinator = SymptomsOriginCoordinator(navigationController: navigationController, parent: self, symptomsParams: symptomsParams)
        addChild(coordinator: symptomsOriginCoordinator)
    }
    
}
