// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingWelcomeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingWelcomeController: OnboardingController {

    override var bottomButtonTitle: String { "onboarding.welcomeController.howDoesItWork".localized }
    
    private var launchScreenController: UIViewController?
    private weak var logoImageView: UIImageView?
    private var popRecognizer: InteractivePopGestureRecognizer?
    private var deinitBlock: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadLaunchScreen()
        setInteractiveRecognizer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hideLaunchScreen()
        }
    }
    
    deinit {
        deinitBlock?()
    }
    
    override func updateTitle() {
        title = "onboarding.welcomeController.title".localized
        super.updateTitle()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        rows.append(titleRow)
        let imageRow: CVRow = CVRow(image: Asset.Images.logo.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: 20.0,
                                                       imageRatio: Appearance.Cell.Image.onboardingControllerRatio),
                                    willDisplay: { [weak self] cell in
            self?.logoImageView = cell.cvImageView
        })
        rows.append(imageRow)
        let textRow: CVRow = CVRow(title: "onboarding.welcomeController.mainMessage.title".localized,
                                   subtitle: "onboarding.welcomeController.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 16.0))
        rows.append(textRow)
        return rows
    }
    
    private func loadLaunchScreen() {
        guard let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else { return }
        launchScreenController = launchScreen
        bottomButtonContainerController?.view.addConstrainedSubview(launchScreen.view)
    }
    
    private func hideLaunchScreen() {
        let imageView: UIView? = launchScreenController?.view.subviews.first
        let logoPoint: CGPoint = launchScreenController?.view.convert(logoImageView?.center ?? .zero, from: logoImageView?.superview) ?? .zero
        let yDifference: CGFloat = logoPoint.y - (imageView?.center.y ?? 0.0)
        let ratio: CGFloat = (logoImageView?.frame.height ?? 0.0) / (imageView?.frame.height ?? 0.0)
        logoImageView?.alpha = 0.0
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: [.curveEaseInOut], animations: {
            imageView?.transform = CGAffineTransform(scaleX: ratio, y: ratio).concatenating(CGAffineTransform(translationX: 0.0, y: yDifference))
        })
        UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
            self.launchScreenController?.view.backgroundColor = .clear
        }) { _ in
            self.logoImageView?.alpha = 1.0
            self.launchScreenController?.view.removeFromSuperview()
            self.launchScreenController = nil
        }
    }
    
    private func setInteractiveRecognizer() {
        guard let navigationController = navigationController else { return }
        popRecognizer = InteractivePopGestureRecognizer(controller: navigationController)
        navigationController.interactivePopGestureRecognizer?.delegate = popRecognizer
    }

}
