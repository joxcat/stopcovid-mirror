// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/10/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class HomeCoordinator: WindowedCoordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator]
    var window: UIWindow!
    
    private weak var navigationController: UINavigationController?
    private var launchScreenWindow: UIWindow?
    private var showLaunchScreen: Bool = true
    
    init(parent: Coordinator) {
        self.parent = parent
        self.childCoordinators = []
        start()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func start() {
        let navigationChildController: UIViewController = CVNavigationChildController.controller(HomeViewController(didTouchAbout: { [weak self] in
            self?.showAbout()
        }, showCaptchaChallenge: { [weak self] captcha, didEnterCaptcha, didCancelCaptcha in
            self?.showCaptchaChallenge(captcha: captcha, didEnterCaptcha: didEnterCaptcha, didCancelCaptcha: didCancelCaptcha)
        }, didTouchTestingSites: { [weak self] in
            self?.showTestingSites()
        }, didTouchDocument: { [weak self] in
            self?.showAttestations()
        }, didTouchManageData: { [weak self] in
            self?.showManageData()
        }, didTouchPrivacy: { [weak self] in
            self?.showPrivacy()
        }, didFinishLoad: { [weak self] in
            self?.didFinishLoadingController()
        }, didTouchHealth: { [weak self] in
            self?.showMyHealth()
        }, didTouchInfo: { [weak self] in
            self?.showInfo()
        }, didTouchKeyFigures: { [weak self] in
            self?.showKeyFigures()
        }, didTouchDeclare: { [weak self] in
            self?.showDeclare()
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        let controller: UIViewController = BottomMessageContainerViewController.controller(navigationChildController)
        let navigationController: UINavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        createWindow(for: navigationController)
        if showLaunchScreen {
            loadLaunchScreen()
        }
    }
    
    private func didFinishLoadingController() {
        if showLaunchScreen {
            hideLaunchScreen()
        }
    }
    
    private func showAbout() {
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
    private func showPrivacy() {
        let privacyCoordinator: PrivacyCoordinator = PrivacyCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: privacyCoordinator)
    }

    private func showAttestations() {
        let attestationsCoordinator: AttestationsCoordinator = AttestationsCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: attestationsCoordinator)
    }

    private func showTestingSites() {
        URL(string: "myHealthController.testingSites.url".localized)?.openInSafari()
    }
    
    private func showManageData() {
        let manageDataController: UIViewController = ManageDataController()
        let navigationController: UIViewController = CVNavigationController(rootViewController: manageDataController)
        self.navigationController?.present(navigationController, animated: true)
    }
    
    private func showMyHealth() {
        let sickCoordinator: SickCoordinator = SickCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: sickCoordinator)
    }
    
    private func showInfo() {
        let infoCenterCoordinator: InfoCenterCoordinator = InfoCenterCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: infoCenterCoordinator)
    }
    
    private func showDeclare() {
        let declareCoordinator: DeclareCoordinator = DeclareCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: declareCoordinator)
    }
    
    private func showCaptchaChallenge(captcha: Captcha, didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), didCancelCaptcha: @escaping () -> ()) {
        let captchaCoordinator: CaptchaCoordinator = CaptchaCoordinator(presentingController: navigationController, parent: self, captcha: captcha, didEnterCaptcha: { [weak self] id, answer in
            self?.navigationController?.dismiss(animated: true) {
                didEnterCaptcha(id, answer)
            }
            }, didCancelCaptcha: { [weak self] in
                self?.navigationController?.dismiss(animated: true)
                didCancelCaptcha()
        })
        addChild(coordinator: captchaCoordinator)
    }
    
    private func showFlash() {
        let flashCodeCoordinator: FlashCodeCoordinator = FlashCodeCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: flashCodeCoordinator)
    }
    private func showEnterCode(code: String?) {
        let enterCodeCoordinator: EnterCodeCoordinator = EnterCodeCoordinator(presentingController: navigationController, parent: self, initialCode: code)
        addChild(coordinator: enterCodeCoordinator)
    }
    
    private func showInformation() {
        let informationCoordinator: InformationCoordinator = InformationCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: informationCoordinator)
    }
    
    private func showKeyFigures() {
        let keyFiguresCoordinator: KeyFiguresCoordinator = KeyFiguresCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: keyFiguresCoordinator)
    }
    
    private func loadLaunchScreen() {
        guard let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else { return }
        let window: UIWindow = UIWindow(frame: UIScreen.main.bounds)
        launchScreenWindow = window
        window.windowLevel = .statusBar
        window.rootViewController = launchScreen
        window.makeKeyAndVisible()
    }
    
    private func hideLaunchScreen() {
        UIView.animate(withDuration: 0.3, animations: {
            self.launchScreenWindow?.alpha = 0.0
        }) { _ in
            self.launchScreenWindow?.resignKey()
            self.launchScreenWindow = nil
        }
    }
    
}

extension HomeCoordinator {
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterCodeFromDeeplink(_:)), name: .didEnterCodeFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newAttestationFromDeeplink(_:)), name: .newAttestationFromDeeplink, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didEnterCodeFromDeeplink(_ notification: Notification) {
        guard let code = notification.object as? String else { return }
        if let controller = DeepLinkingManager.shared.enterCodeController {
            controller.enterCode(code)
        } else {
            showEnterCode(code: code)
        }
    }
    
    @objc private func newAttestationFromDeeplink(_ notification: Notification) {
        showAttestations()
    }
    
}
