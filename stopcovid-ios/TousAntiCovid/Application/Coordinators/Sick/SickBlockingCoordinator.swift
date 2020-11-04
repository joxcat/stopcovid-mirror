// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickBlockingCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RobertSDK

final class SickBlockingCoordinator: WindowedCoordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator]
    var window: UIWindow!
    
    private weak var currentController: UIViewController?
    
    init(parent: Coordinator) {
        self.parent = parent
        self.childCoordinators = []
        start()
    }
    
    func createWindow(for controller: UIViewController) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .clear
        window?.rootViewController = controller
        window?.accessibilityViewIsModal = true
        window?.alpha = 0.0
        window?.makeKeyAndVisible()
    }
    
    private func start() {
        let controller: UIViewController = CVNavigationChildController.controller(SickController(didTouchAbout: { [weak self] in
            self?.didTouchAbout()
        }, didTouchReadMore: {}))
        currentController = controller
        createWindow(for: controller)
    }
    
    private func didTouchAbout() {
        let coordinator: AboutCoordinator = AboutCoordinator(presentingController: currentController, parent: self)
        addChild(coordinator: coordinator)
    }
    
}
