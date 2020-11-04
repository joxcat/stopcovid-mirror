// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationsCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD

final class AttestationsCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: AttestationsViewController { [weak self] in
            self?.openNewAttestation()
        } didTouchTermsOfUse: { [weak self] in
            self?.openTermsOfUse()
        } didTouchWebAttestation: { [weak self] in
            self?.openWebAttestation()
        } didTouchAttestationQrCode: { [weak self] qrCode, text in
            self?.showAttestationQRCodeFullscreen(qrCode, text: text)
        } deinitBlock: { [weak self] in
            self?.didDeinit()
        })
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
    private func openNewAttestation() {
        HUD.show(.progress)
        AttestationsManager.shared.fetchAttestationForm(timeout: 2.0) {
            HUD.hide()
            let newAttestationCoordinator: NewAttestationCoordinator = NewAttestationCoordinator(presentingController: self.navigationController, parent: self)
            self.addChild(coordinator: newAttestationCoordinator)
        }
    }
    
    private func openTermsOfUse() {
        URL(string: "attestationsController.termsOfUse.url".localized)?.openInSafari()
    }
    
    private func openWebAttestation() {
        URL(string: "home.moreSection.curfewCertificate.url".localized)?.openInSafari()
    }
    
    private func showAttestationQRCodeFullscreen(_ qrCode: UIImage, text: String) {
        let controller: UIViewController = AttestationFullScreenViewController.controller(qrCode: qrCode, text: text)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        navigationController?.present(controller, animated: true)
    }
    
}
