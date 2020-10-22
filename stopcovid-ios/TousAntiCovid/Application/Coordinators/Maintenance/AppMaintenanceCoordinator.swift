// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AppMaintenanceCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2020 - for the TousAntiCovid project.
//


import UIKit

final class AppMaintenanceCoordinator: WindowedCoordinator {
    
    weak var parent: Coordinator?
    var childCoordinators: [Coordinator]
    var window: UIWindow!
    private let maintenanceInfo: MaintenanceInfo
    
    private weak var currentController: MaintenanceController?
    
    init(parent: Coordinator, maintenanceInfo: MaintenanceInfo) {
        self.parent = parent
        self.childCoordinators = []
        self.maintenanceInfo = maintenanceInfo
        start()
    }
    
    func updateMaintenanceInfo(_ maintenanceInfo: MaintenanceInfo) {
        currentController?.maintenanceInfo = maintenanceInfo
    }
    
    private func start() {
        let controller: AppMaintenanceController = AppMaintenanceController(maintenanceInfo: maintenanceInfo) { [weak self] in
            self?.didTouchAbout()
        }
        currentController = controller
        let navController: UIViewController = UINavigationController(rootViewController: controller)
        createWindow(for: navController)
        UIView.animate(withDuration: 0.2) {
            self.window?.alpha = 1.0
        }
    }
    
    private func didTouchAbout() {
        let coordinator: AboutCoordinator = AboutCoordinator(presentingController: currentController, parent: self)
        addChild(coordinator: coordinator)
    }
    
}
