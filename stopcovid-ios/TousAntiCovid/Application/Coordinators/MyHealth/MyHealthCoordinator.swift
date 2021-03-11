// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MyHealthCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK

final class MyHealthCoordinator: Coordinator {

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
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: MyHealthController(didTouchAbout: { [weak self] in
            self?.showAbout()
        }, didTouchCautionMeasures: { [weak self] in
            self?.showGestures()
        }, didTouchRisksUILevelSectionLink: { [weak self] link in
            self?.showLinkAction(for: link)
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

    private func showLinkAction(for link: RisksUILevelSectionLink?) {
        guard let link = link else { return }
        switch link.type {
        case .web:
            URL(string: link.action.localized)?.openInSafari()
        case .ctrl:
            guard link.action == "GESTURES" else { return }
            self.showGestures()
        }
    }
    
    private func showAbout() {
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
    private func showGestures() {
        let gesturesCoordinator: GesturesCoordinator = GesturesCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: gesturesCoordinator)
    }
    
}
