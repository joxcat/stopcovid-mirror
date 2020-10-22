// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RootCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK

final class RootCoordinator: Coordinator {

    enum State {
        case onboarding
        case main
        case off
        case unknown
    }

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private var state: State = .unknown
    private weak var currentCoordinator: WindowedCoordinator?
    private var powerSaveModeWindow: UIWindow?
    private var lastBrightnessLevel: CGFloat = UIScreen.main.brightness
    private var isPowerSaveMode: Bool = false
    private var didStartOnboarding: Bool = false

    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false {
        didSet {
            if #available(iOS 14.0, *) {
                WidgetManager.shared.isOnboardingDone = isOnboardingDone
            }
        }
    }

    func start() {
        if #available(iOS 14.0, *) {
            WidgetManager.shared.isOnboardingDone = isOnboardingDone
        }
        if RBManager.shared.isSick {
            switchTo(state: .off)
        } else {
            switchTo(state: currentNotBlockingState())
        }
        addObservers()
    }
    
    private func currentNotBlockingState() -> State {
        isOnboardingDone ? .main : .onboarding
    }

    private func switchTo(state: State) {
        self.state = state
        if let newCoordinator: WindowedCoordinator = coordinator(for: state) {
            if currentCoordinator != nil {
                processCrossFadingAnimation(newCoordinator: newCoordinator)
            } else {
                currentCoordinator = newCoordinator
                currentCoordinator?.window.alpha = 1.0
                addChild(coordinator: newCoordinator)
            }
        } else {
            childCoordinators.removeAll()
        }
    }

    private func coordinator(for state: State) -> WindowedCoordinator? {
        let coordinator: WindowedCoordinator?
        switch state {
        case .onboarding:
            coordinator = OnboardingCoordinator(parent: self) { [weak self] in self?.onboardingDidEnd() }
        case .main:
            coordinator = HomeCoordinator(parent: self, didFinishLoadingController: {})
        case .off:
            coordinator = SickBlockingCoordinator(parent: self)
        default:
            return nil
        }
        didStartOnboarding = state == .onboarding
        return coordinator
    }

    private func onboardingDidEnd() {
        isOnboardingDone = true
        switchTo(state: currentNotBlockingState())
    }

}

extension RootCoordinator {
    
    private func processCrossFadingAnimation(newCoordinator: WindowedCoordinator) {
        guard let currentCoordinator = currentCoordinator else { return }
        newCoordinator.window.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.3, animations: {
            newCoordinator.window.alpha = 1.0
            newCoordinator.window.transform = .identity
            currentCoordinator.window.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            currentCoordinator.window.alpha = 0.0
        }) { _ in
            currentCoordinator.window?.isHidden = true
            currentCoordinator.window?.resignKey()
            currentCoordinator.window = nil
            self.currentCoordinator = newCoordinator
            self.removeChild(coordinator: currentCoordinator)
            self.addChild(coordinator: newCoordinator)
        }
    }
    
}

// MARK: - Notifications -
extension RootCoordinator {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeAppStateNotification), name: .changeAppState, object: nil)
    }
    
    @objc private func statusDataChanged() {
        if RBManager.shared.isSick {
            guard state != .off else { return }
            switchTo(state: .off)
        } else {
            let state: State = currentNotBlockingState()
            guard self.state != state else { return }
            switchTo(state: state)
        }
    }
    
    @objc private func changeAppStateNotification(_ notification: Notification) {
        guard let state = notification.object as? State else { return }
        if state == .onboarding {
            isOnboardingDone = false
        }
        switchTo(state: state)
    }
    
}

// MARK: - Maintenance -
extension RootCoordinator: MaintenanceSupportingCoordinator {
    
    func showMaintenance(info: MaintenanceInfo) {
        guard !isAppMaintenanceVisible() else {
            appMaintenanceCoordinator()?.updateMaintenanceInfo(info)
            return
        }
        let coordinator: AppMaintenanceCoordinator = AppMaintenanceCoordinator(parent: self, maintenanceInfo: info)
        addChild(coordinator: coordinator)
    }
    
    func hideMaintenance() {
        guard let coordinator = appMaintenanceCoordinator() else { return }
        UIView.animate(withDuration: 0.2, animations: {
            coordinator.window.alpha = 0.0
        }) { _ in
            self.removeChild(coordinator: coordinator)
        }
    }
    
    private func isAppMaintenanceVisible() -> Bool {
        appMaintenanceCoordinator() != nil
    }
    
    private func appMaintenanceCoordinator() -> AppMaintenanceCoordinator? {
        childCoordinators.compactMap({ $0 as? AppMaintenanceCoordinator }).first
    }
    
}
