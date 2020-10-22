// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingExplanationsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingExplanationsController: OnboardingController {
    
    override var bottomButtonTitle: String { "onboarding.explanationsController.dataPrivacy".localized }
    
    override func updateTitle() {
        title = "onboarding.explanationsController.title".localized
        super.updateTitle()
    }
    
    override func createRows() -> [CVRow] {
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        let stepsRows: [CVRow] = steps().enumerated().map { index, step in
            CVRow(title: step.title,
                  subtitle: step.subtitle,
                  accessoryText: "\(index + 1)",
                  xibName: .onboardingWorkingStepCell,
                  theme: CVRow.Theme(topInset: index == 0 ? 4.0 : 20.0))
        }
        return [titleRow] + stepsRows
    }
    
    private func steps() -> [Step] {
        return [Step(title: "onboarding.explanationsController.stepFollow.title".localized,
                     subtitle: "onboarding.explanationsController.stepFollow.subtitle".localized),
                Step(title: "onboarding.explanationsController.stepInform.title".localized,
                     subtitle: "onboarding.explanationsController.stepInform.subtitle".localized),
                Step(title: "onboarding.explanationsController.stepBeAware.title".localized,
                     subtitle: "onboarding.explanationsController.stepBeAware.subtitle".localized)]
    }
    
}
