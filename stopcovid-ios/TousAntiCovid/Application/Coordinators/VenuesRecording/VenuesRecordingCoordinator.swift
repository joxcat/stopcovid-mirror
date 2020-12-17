// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesRecordingCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class VenuesRecordingCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []

    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?

    @UserDefault(key: .didAlreadySeeVenuesRecordingOnboarding)
    private var didAlreadySeeOnboarding: Bool = false
    private var showOnlyConfirmation: Bool = false
    private var openingUrl: URL?
    
    init(presentingController: UIViewController?, parent: Coordinator?, showOnlyConfirmation: Bool = false, openingUrl: URL? = nil) {
        self.presentingController = presentingController
        self.parent = parent
        self.showOnlyConfirmation = showOnlyConfirmation
        self.openingUrl = openingUrl
        start()
    }
    
    private func start() {
        if let openingUrl = openingUrl, showOnlyConfirmation {
            startConfirmation(venueType: VenuesManager.shared.venueTypeFrom(url: openingUrl))
        } else if didAlreadySeeOnboarding {
            startFlashCode()
        } else {
            startOnboarding()
        }
    }

    private func startOnboarding() {
        let navigationController: CVNavigationController
        let controller: VenuesRecordingOnboardingController = VenuesRecordingOnboardingController(didContinue: { [weak self] in
            self?.didTouchContinue()
        }, deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        navigationController = CVNavigationController(rootViewController: BottomButtonContainerController.controller(controller))
        self.navigationController = navigationController
        presentingController?.topPresentedController.present(navigationController, animated: true)
    }

    private func startFlashCode() {
        let navigationController: CVNavigationController
        navigationController = CVNavigationController(rootViewController: flashCodeController())
        self.navigationController = navigationController
        presentingController?.topPresentedController.present(navigationController, animated: true)
    }

    private func startConfirmation(venueType: String) {
        let navigationController: CVNavigationController
        navigationController = CVNavigationController(rootViewController: confirmationController(venueType: venueType))
        self.navigationController = navigationController
        presentingController?.topPresentedController.present(navigationController, animated: true)
    }

    private func showFlashCode() {
        navigationController?.pushViewController(flashCodeController(needDeinit: false), animated: true)
    }
    
    private func flashCodeController(needDeinit: Bool = true) -> UIViewController {
        FlashVenueCodeController.controller(didFlash: { [weak self] stringUrl in
            guard let stringUrl = stringUrl else { return false }
            guard let url = URL(string: stringUrl) else { return false }
            guard VenuesManager.shared.processVenueUrl(url) else { return false }
            self?.showConfirmation(venueType: VenuesManager.shared.venueTypeFrom(url: url))
            return true
        }, deinitBlock: needDeinit ? { [weak self] in
            self?.didDeinit()
        } : nil)
    }

    private func confirmationController(venueType: String) -> UIViewController {
        let controller: UIViewController = VenuesRecordingConfirmationController(venueType: venueType, didFinish: { [weak self] in
            self?.didTouchFinish()
        })
        return BottomButtonContainerController.controller(controller)
    }
    
    private func showConfirmation(venueType: String) {
        navigationController?.pushViewController(confirmationController(venueType: venueType), animated: true)
    }

}

// MARK: - Flow management -
extension VenuesRecordingCoordinator {

    private func didTouchContinue() {
        didAlreadySeeOnboarding = true
        showFlashCode()
    }

    private func didTouchFinish() {
        navigationController?.dismiss(animated: true)
    }
}
