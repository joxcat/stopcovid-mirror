// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureDetailCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class KeyFigureDetailCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private let keyFigure: KeyFigure
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?

    init(presentingController: UIViewController?, parent: Coordinator, keyFigure: KeyFigure) {
        self.presentingController = presentingController
        self.parent = parent
        self.keyFigure = keyFigure
        start()
    }

    private func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: KeyFigureDetailController(keyFigure: keyFigure, deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }

}
