// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesPrivateEventCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class VenuesPrivateEventCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator?) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        let navigationController: CVNavigationController
        let controller: VenuesPrivateEventController = VenuesPrivateEventController(deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        navigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

}
