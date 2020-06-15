// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SharingCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit

final class SharingCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var tabBarController: UITabBarController?
    private weak var currentController: UIViewController?
    
    init(in tabBarController: UITabBarController, parent: Coordinator) {
        self.tabBarController = tabBarController
        self.parent = parent
        start()
    }
    
    private func start() {
        let navigationChildController: UIViewController = CVNavigationChildController.controller(SharingController { [weak self] in
            self?.showAbout()
        })
        navigationChildController.tabBarItem.image = Asset.Images.tabBarSharingNormal.image
        navigationChildController.tabBarItem.selectedImage = Asset.Images.tabBarSharingSelected.image
        navigationChildController.tabBarItem.title = "sharingController.tabBar.title".localized
        self.currentController = navigationChildController
        var tabBarViewControllers: [UIViewController] = tabBarController?.viewControllers ?? []
        tabBarViewControllers.append(navigationChildController)
        tabBarController?.viewControllers = tabBarViewControllers
        tabBarController?.tabBar.layoutSubviews()
    }
    
    private func showAbout() {
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: currentController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
}
