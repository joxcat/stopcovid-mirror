// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCenterCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class InfoCenterCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    deinit {
        InfoCenterManager.shared.removeObserver(self)
    }
    
    private func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: InfoCenterController(deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
        InfoCenterManager.shared.addObserver(self)
    }
    
}

extension InfoCenterCoordinator: InfoCenterChangesObserver {

    func infoCenterDidUpdate() {
        navigationController?.children.first?.tabBarItem.badgeValue = InfoCenterManager.shared.didReceiveNewInfo ? "1" : nil
    }

}
