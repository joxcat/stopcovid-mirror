// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class KeyFiguresCoordinator: Coordinator {

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
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: KeyFiguresController(didTouchReadExplanationsNow: { [weak self] in
            self?.showKeyFiguresExplanations()
        }, didTouchKeyFigure: { [weak self] keyFigure in
            self?.showKeyFigureDetailFor(keyFigure: keyFigure)
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

    private func showKeyFiguresExplanations() {
        let explanationsController: KeyFiguresExplanationsController = KeyFiguresExplanationsController()
        navigationController?.pushViewController(explanationsController, animated: true)
    }
    
    private func showKeyFigureDetailFor(keyFigure: KeyFigure) {
        let detailCoordinator: KeyFigureDetailCoordinator = KeyFigureDetailCoordinator(presentingController: navigationController, parent: self, keyFigure: keyFigure)
        addChild(coordinator: detailCoordinator)
    }

}
