// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingWorkingStepCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class OnboardingWorkingStepCell: CVTableViewCell {
    
    @IBOutlet private var circleView: UIView!
    @IBOutlet private var digitLabel: UILabel!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        digitLabel.text = row.accessoryText
        setupTheme()
        setupAccessibility(with: row)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.frame.height / 2.0
    }
    
    private func setupTheme() {
        circleView.backgroundColor = Appearance.Cell.Onboarding.stepBackgroundColor
        digitLabel.font = Appearance.Cell.Onboarding.stepFont
        digitLabel.textColor = Appearance.Cell.Onboarding.stepColor
    }
    
    private func setupAccessibility(with row: CVRow) {
        accessibilityElements = [digitLabel, cvTitleLabel, cvSubtitleLabel].compactMap { $0 }
        digitLabel.accessibilityLabel = "accessibility.onboarding.explanations.step\(row.accessoryText ?? "")".localized
    }

}
