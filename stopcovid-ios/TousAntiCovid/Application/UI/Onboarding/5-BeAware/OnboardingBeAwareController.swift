// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingBeAwareController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingBeAwareController: OnboardingController {

    override var bottomButtonTitle: String { "onboarding.beAwareController.allowNotifications".localized }
    
    override func updateTitle() {
        title = "onboarding.beAwareController.title".localized
        super.updateTitle()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        rows.append(titleRow)
        let imageRow: CVRow = CVRow(image: Asset.Images.notification.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(imageRatio: Appearance.Cell.Image.onboardingControllerRatio))
        rows.append(imageRow)
        let textRow: CVRow = CVRow(title: "onboarding.beAwareController.mainMessage.title".localized,
                                   subtitle: "onboarding.beAwareController.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 20.0,
                                                      titleFont: { Appearance.Cell.Text.smallHeadTitleFont }))
        rows.append(textRow)
        return rows
    }
    
    override func bottomContainerButtonTouched() {
        NotificationsManager.shared.requestAuthorization { granted in
            super.bottomContainerButtonTouched()
        }
    }

}
