// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class CaptchaCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var presentingController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let initialCaptcha: Captcha
    private let didEnterCaptcha: (_ id: String, _ answer: String) -> ()
    private let didCancelCaptcha: () -> ()

    
    init(presentingController: UIViewController?, parent: Coordinator, captcha: Captcha, didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), didCancelCaptcha: @escaping () -> ()) {
        self.presentingController = presentingController
        self.parent = parent
        self.initialCaptcha = captcha
        self.didEnterCaptcha = didEnterCaptcha
        self.didCancelCaptcha = didCancelCaptcha
        start()
    }
    
    private func start() {
        let controller: UIViewController = CaptchaViewController(captcha: initialCaptcha, didEnterCaptcha: { [weak self] id, answer in
            self?.didEnterCaptcha(id, answer)
        }, didCancelCaptcha: { [weak self] in
            self?.didCancelCaptcha()
        }) { [weak self] in
            self?.didDeinit()
        }
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: controller)
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true, completion: nil)
    }
    
}
