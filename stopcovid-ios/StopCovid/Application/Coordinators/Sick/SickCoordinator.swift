// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit

final class SickCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var tabBarController: UITabBarController?
    private weak var navigationController: UINavigationController?
    
    init(in tabBarController: UITabBarController, parent: Coordinator) {
        self.tabBarController = tabBarController
        self.parent = parent
        start()
    }
    
    private func start() {
        let navigationChildController: UIViewController = CVNavigationChildController.controller(SickController(didTouchAbout: { [weak self] in
            self?.showAbout()
        }, didTouchFlash: { [weak self] in
            self?.showFlash()
        }, didTouchTap: { [weak self] in
            self?.showTap()
        }, didTouchReadMore: { [weak self] in
            self?.showInformation()
        }))
        navigationChildController.tabBarItem.image = Asset.Images.tabBarSickNormal.image
        navigationChildController.tabBarItem.selectedImage = Asset.Images.tabBarSickSelected.image
        navigationChildController.tabBarItem.title = "sickController.tabBar.title".localized
        let navigationController: UINavigationController = CVNavigationController(rootViewController: navigationChildController)
        self.navigationController = navigationController
        var tabBarViewControllers: [UIViewController] = tabBarController?.viewControllers ?? []
        tabBarViewControllers.append(navigationController)
        tabBarController?.viewControllers = tabBarViewControllers
        tabBarController?.tabBar.layoutSubviews()
    }
    
    private func showAbout() {
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
    private func showFlash() {
        let flashCodeCoordinator: FlashCodeCoordinator = FlashCodeCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: flashCodeCoordinator)
    }
    
    private func showTap() {
        let enterCodeCoordinator: EnterCodeCoordinator = EnterCodeCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: enterCodeCoordinator)
    }
    
    private func showInformation() {
        let informationCoordinator: InformationCoordinator = InformationCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: informationCoordinator)
    }
    
}
