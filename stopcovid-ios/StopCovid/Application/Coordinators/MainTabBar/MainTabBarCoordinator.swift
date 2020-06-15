// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MainTabBarCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit

final class MainTabBarCoordinator: WindowedCoordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    var window: UIWindow!
    private weak var tabBarController: UITabBarController?
    
    init(parent: Coordinator) {
        self.parent = parent
        start()
    }
    
    deinit {
        removeObservers()
    }
    
    private func start() {
        let mainTabBarController: MainTabBarController = MainTabBarController()
        mainTabBarController.configureTabBarAppearance()
        self.tabBarController = mainTabBarController
        Constant.Tab.allCases.forEach { tab in
            addChild(coordinator: coordinatorFor(tab: tab, tabBarController: mainTabBarController))
        }
        createWindow(for: mainTabBarController)
        addObservers()
    }
    
    private func coordinatorFor(tab: Constant.Tab, tabBarController: UITabBarController) -> Coordinator {
        let coordinator: Coordinator
        switch tab {
        case .proximity:
            coordinator = ProximityCoordinator(in: tabBarController, parent: self)
        case .sharing:
            coordinator = SharingCoordinator(in: tabBarController, parent: self)
        case .sick:
            coordinator = SickCoordinator(in: tabBarController, parent: self)
        }
        return coordinator
    }
    
    private func showInformation() {
        let informationCoordinator: InformationCoordinator = InformationCoordinator(presentingController: tabBarController?.topPresentedController, parent: self)
        addChild(coordinator: informationCoordinator)
    }
}

// MARK: - Notifications -
extension MainTabBarCoordinator {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(selectTabNotificationReceived(_:)), name: .selectTab, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTouchAtRiskNotification(_:)), name: .didTouchAtRiskNotification, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func selectTabNotificationReceived(_ notification: Notification) {
        guard let tab = notification.object as? Constant.Tab else { return }
        tabBarController?.selectedIndex = tab.rawValue
    }
    
    @objc private func didTouchAtRiskNotification(_ notification: Notification) {
       showInformation()
    }
    
}
