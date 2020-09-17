// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ProximityCoordinator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit

final class ProximityCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var tabBarController: UITabBarController?
    private weak var navigationController: UINavigationController?
    private var didFinishLoadingController: (() -> ())?
    
    init(in tabBarController: UITabBarController, parent: Coordinator, didFinishLoadingController: (() -> ())?) {
        self.tabBarController = tabBarController
        self.parent = parent
        self.didFinishLoadingController = didFinishLoadingController
        start()
    }
    
    private func start() {
        let navigationChildController: UIViewController = CVNavigationChildController.controller(ProximityController(didTouchAbout: { [weak self] in
            self?.showAbout()
        }, showCaptchaChallenge: { [weak self] captcha, didEnterCaptcha, didCancelCaptcha in
            self?.showCaptchaChallenge(captcha: captcha, didEnterCaptcha: didEnterCaptcha, didCancelCaptcha: didCancelCaptcha)
        }, didTouchManageData: { [weak self] in
            self?.showManageData()
        }, didTouchPrivacy: { [weak self] in
            self?.showPrivacy()
        }, didFinishLoad: { [weak self] in
            self?.didFinishLoadingController?()
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        }))
        let controller: UIViewController = BottomMessageContainerViewController.controller(navigationChildController)
        let navigationController: UINavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        navigationController.tabBarItem.image = Asset.Images.tabBarProximityNormal.image
        navigationController.tabBarItem.selectedImage = Asset.Images.tabBarProximitySelected.image
        navigationController.tabBarItem.title = "proximityController.tabBar.title".localized
        var tabBarViewControllers: [UIViewController] = tabBarController?.viewControllers ?? []
        tabBarViewControllers.append(navigationController)
        tabBarController?.viewControllers = tabBarViewControllers
        tabBarController?.tabBar.layoutSubviews()
    }
    
    private func showAbout() {
        let aboutCoordinator: AboutCoordinator = AboutCoordinator(presentingController: navigationController, parent: self)
        addChild(coordinator: aboutCoordinator)
    }
    
    private func showPrivacy() {
        let privacyCoordinator: PrivacyCoordinator = PrivacyCoordinator(navigationController: navigationController, parent: self)
        addChild(coordinator: privacyCoordinator)
    }
    
    private func showManageData() {
        let manageDataController: UIViewController = ManageDataController()
        let controller: UIViewController = CVNavigationChildController.controller(manageDataController)
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
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
    
}
