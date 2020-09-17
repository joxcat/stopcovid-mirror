// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RootCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
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
    private var isOnboardingDone: Bool = false

    func start() {
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
            coordinator = MainTabBarCoordinator(parent: self, showLaunchScreen: !didStartOnboarding)
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

// MARK: - Notifications -
extension RootCoordinator {
    
    private func addObservers() {
        OrientationManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeAppStateNotification), name: .changeAppState, object: nil)
    }
    
    @objc private func appWillResignActive() {
        guard isPowerSaveMode else { return }
        restoreBrightness()
    }
    
    @objc private func appDidBecomeActive() {
        guard isPowerSaveMode else { return }
        reduceBrightness()
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

// MARK: - Power save mode management -
extension RootCoordinator {
    
    private func showPowerSaveModeWindow() {
        reduceBrightness()
        isPowerSaveMode = true
        powerSaveModeWindow = UIWindow(frame: UIScreen.main.bounds)
        powerSaveModeWindow?.backgroundColor = .clear
        powerSaveModeWindow?.rootViewController = StoryboardScene.PowerSaveMode.initialScene.instantiate()
        powerSaveModeWindow?.accessibilityViewIsModal = true
        powerSaveModeWindow?.alpha = 0.0
        powerSaveModeWindow?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        powerSaveModeWindow?.makeKeyAndVisible()
        UIView.animate(withDuration: 0.3, animations: {
            self.powerSaveModeWindow?.alpha = 1.0
            self.powerSaveModeWindow?.transform = .identity
        })
    }
    
    private func hidePowerSaveModeWindow() {
        restoreBrightness()
        isPowerSaveMode = false
        UIView.animate(withDuration: 0.3, animations: {
            self.currentCoordinator?.window.makeKey()
            self.powerSaveModeWindow?.alpha = 0.0
            self.powerSaveModeWindow?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.powerSaveModeWindow?.isHidden = true
            self.powerSaveModeWindow = nil
            self.currentCoordinator?.window.rootViewController?.setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }
    
    private func reduceBrightness() {
        lastBrightnessLevel = UIScreen.main.brightness
        updateBrightnessTo(level: 0.1, decrease: true)
    }
    
    private func restoreBrightness() {
        if UIScreen.main.brightness < lastBrightnessLevel {
            updateBrightnessTo(level: lastBrightnessLevel, decrease: false)
        }
    }
    
    private func updateBrightnessTo(level: CGFloat, decrease: Bool = true) {
        let currentBrightness: CGFloat = UIScreen.main.brightness
        guard (decrease && currentBrightness > level) || (!decrease && currentBrightness < level) else { return }
        if decrease {
            UIScreen.main.brightness = currentBrightness - 0.05
        } else {
            UIScreen.main.brightness = currentBrightness + 0.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.updateBrightnessTo(level: level, decrease: decrease)
        }
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

// MARK: - Orientation -
extension RootCoordinator: OrientationChangesObserver {
    
    func orientationActivationStateDidChange() {
        OrientationManager.shared.isPowerSaveModeOrientation ? showPowerSaveModeWindow() : hidePowerSaveModeWindow()
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
