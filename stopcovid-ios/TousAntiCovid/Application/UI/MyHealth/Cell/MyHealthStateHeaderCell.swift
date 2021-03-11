// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MyHealthStateHeaderCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import UIKit

final class MyHealthStateHeaderCell: CVTableViewCell {

    @IBOutlet private var exposureDateStackView: UIStackView?
    @IBOutlet private var exposureDateTitleLabel: UILabel?
    @IBOutlet private var exposureDateLabel: UILabel?
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var gradientView: GradientView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupTheme(with: row)
        setupContent(with: row)
        accessoryType = .none
        selectionStyle = .none
    }
    
    private func setupTheme(with row: CVRow) {
        guard let currentRiskLevel = row.associatedValue as? RisksUILevel else { return }
        cvTitleLabel?.textColor = .white
        cvSubtitleLabel?.textColor = .white
        cvAccessoryLabel?.textColor = .white
        exposureDateTitleLabel?.textColor = .white
        exposureDateLabel?.textColor = .white
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        gradientView.startColor = currentRiskLevel.color.fromColor
        gradientView.endColor = currentRiskLevel.color.toColor
        exposureDateStackView?.isHidden = row.footerText == nil
        exposureDateTitleLabel?.textAlignment = row.theme.textAlignment
        exposureDateLabel?.textAlignment = row.theme.textAlignment
        exposureDateTitleLabel?.adjustsFontForContentSizeCategory = true
        exposureDateLabel?.adjustsFontForContentSizeCategory = true
        exposureDateTitleLabel?.font = row.theme.subtitleFont()
        exposureDateLabel?.font = Appearance.Cell.Text.actionTitleFont
    }
    
    private func setupContent(with row: CVRow) {
        exposureDateTitleLabel?.text = "myHealthStateHeaderCell.exposureDate.title".localized
        exposureDateLabel?.text = row.footerText
    }
    
}
