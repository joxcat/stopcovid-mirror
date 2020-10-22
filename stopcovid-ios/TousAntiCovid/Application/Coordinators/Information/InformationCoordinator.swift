// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InformationCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class InformationCoordinator: Coordinator {

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
        let navigationController: UINavigationController = CVNavigationController(rootViewController: InformationController(showGesturesBlock: { [weak self] in
            self?.showGestures()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true, completion: nil)
    }
    
    private func showGestures() {
        let gesturesCoordinator: GesturesCoordinator = GesturesCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: gesturesCoordinator)
    }
    
}
