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
import RobertSDK

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
        }, didTouchKeyFigure: { [weak self] keyFigure in
            self?.showKeyFigureDetailFor(keyFigure: keyFigure)
        }, didTouchKeyFigures: { [weak self] in
            self?.showKeyFigures()
        }, didTouchDeclare: { [weak self] in
            self?.showDeclare()
        }, didTouchUsefulLinks: { [weak self] in
            self?.showUsefulLinks()
        }, didTouchRecordVenues: { [weak self] in
            self?.showRecordVenues()
        }, didTouchPrivateEvents: { [weak self] in
            self?.showPrivateEvents()
        }, didTouchVenuesHistory: { [weak self] in
            self?.showVenuesHistory()
        }, didRecordVenue: { [weak self] url in
            self?.showVenueRecordingConfirmation(url: url)
        }, didRequestVenueScanAuthorization: { [weak self] completion in
            self?.requestVenueScanAuthorization(completion)
        }, didTouchOpenIsolationForm: { [weak self] in
            self?.showIsolationForm()
        }, didTouchVaccination: { [weak self] in
            self?.showVaccination()
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
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
    private func showUsefulLinks() {
        let linksCoordinator: LinksCoordinator = LinksCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: linksCoordinator)
    }
    
    private func showPrivacy() {
        let privacyCoordinator: PrivacyCoordinator = PrivacyCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: privacyCoordinator)
    }

    private func showAttestations() {
        let attestationsCoordinator: AttestationsCoordinator = AttestationsCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: attestationsCoordinator)
    }

    private func showVenueRecordingConfirmation(url: URL) {
        let venuesRecordingCoordinator: VenuesRecordingCoordinator = VenuesRecordingCoordinator(presentingController: navigationController?.topPresentedController, parent: self, showOnlyConfirmation: true, openingUrl: url)
        addChild(coordinator: venuesRecordingCoordinator)
    }
    
    private func requestVenueScanAuthorization(_ completion: @escaping (_ granted: Bool) -> ()) {
        let venueScanAuthorizationController: VenuesScanAuthorizationController = VenuesScanAuthorizationController { [weak self] granted in
            if granted {
                self?.navigationController?.topPresentedController.dismiss(animated: true) {
                    completion(true)
                }
            } else {
                self?.navigationController?.topPresentedController.dismiss(animated: true)
                completion(false)
            }
        }
        let navigationController: UIViewController = CVNavigationController(rootViewController: venueScanAuthorizationController)
        self.navigationController?.topPresentedController.present(navigationController, animated: true)
    }
    
    private func showManageData() {
        let manageDataController: UIViewController = ManageDataController()
        let navigationController: UIViewController = CVNavigationController(rootViewController: manageDataController)
        self.navigationController?.present(navigationController, animated: true)
    }
    
    private func showMyHealth() {
        let sickCoordinator: SickCoordinator = SickCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: sickCoordinator)
    }
    
    private func showInfo() {
        let infoCenterCoordinator: InfoCenterCoordinator = InfoCenterCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: infoCenterCoordinator)
    }
    
    private func showDeclare() {
        let declareCoordinator: DeclareCoordinator = DeclareCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: declareCoordinator)
    }
    
    private func showRecordVenues() {
        let venuesRecordingCoordinator: VenuesRecordingCoordinator = VenuesRecordingCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: venuesRecordingCoordinator)
    }
    
    private func showPrivateEvents() {
        if VenuesManager.shared.needPrivateEventQrCodeGeneration {
            HUD.show(.progress)
            DispatchQueue.main.async {
                VenuesManager.shared.generateNewPrivateEventQrCode()
                HUD.hide()
                self.showPrivateEventController()
            }
        } else {
            self.showPrivateEventController()
        }
    }
    
    private func showPrivateEventController() {
        let privateEventCoordinator: VenuesPrivateEventCoordinator = VenuesPrivateEventCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: privateEventCoordinator)
    }
    
    private func showVenuesHistory() {
        let venuesHistoryController: UIViewController = VenuesHistoryViewController()
        let navigationController: UIViewController = CVNavigationController(rootViewController: venuesHistoryController)
        self.navigationController?.present(navigationController, animated: true)
    }
    
    private func showIsolationForm() {
        let isolationFormCoordinator: IsolationFormCoordinator = IsolationFormCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: isolationFormCoordinator)
    }
    
    private func showCaptchaChallenge(captcha: Captcha, didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), didCancelCaptcha: @escaping () -> ()) {
        let captchaCoordinator: CaptchaCoordinator = CaptchaCoordinator(presentingController: navigationController?.topPresentedController, parent: self, captcha: captcha, didEnterCaptcha: { [weak self] id, answer in
            self?.navigationController?.topPresentedController.dismiss(animated: true) {
                didEnterCaptcha(id, answer)
            }
        }, didCancelCaptcha: { [weak self] in
            self?.navigationController?.topPresentedController.dismiss(animated: true)
            didCancelCaptcha()
        })
        addChild(coordinator: captchaCoordinator)
    }
    
    private func showFlash() {
        let flashCodeCoordinator: FlashCodeCoordinator = FlashCodeCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: flashCodeCoordinator)
    }
    private func showEnterCode(code: String?) {
        let enterCodeCoordinator: EnterCodeCoordinator = EnterCodeCoordinator(presentingController: navigationController?.topPresentedController, parent: self, initialCode: code)
        addChild(coordinator: enterCodeCoordinator)
    }
    
    private func showKeyFigures() {
        let keyFiguresCoordinator: KeyFiguresCoordinator = KeyFiguresCoordinator(presentingController: navigationController?.topPresentedController, parent: self)
        addChild(coordinator: keyFiguresCoordinator)
    }
    
    private func showKeyFigureDetailFor(keyFigure: KeyFigure) {
        let detailCoordinator: KeyFigureDetailCoordinator = KeyFigureDetailCoordinator(presentingController: navigationController, parent: self, keyFigure: keyFigure)
        addChild(coordinator: detailCoordinator)
    }
    
    private func showVaccination() {
        let vaccinationCoordinator: VaccinationCoordinator = VaccinationCoordinator(presentingController: navigationController?.topViewController, parent: self)
        addChild(coordinator: vaccinationCoordinator)
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
        NotificationCenter.default.addObserver(self, selector: #selector(newAttestationFromDeeplink), name: .newAttestationFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissAllAndShowRecommandations), name: .dismissAllAndShowRecommandations, object: nil)
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
    
    @objc private func newAttestationFromDeeplink() {
        showAttestations()
    }
    
    @objc private func dismissAllAndShowRecommandations() {
        navigationController?.dismiss(animated: true) {
            self.showMyHealth()
        }
    }
    
}
