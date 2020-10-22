// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class KeyFigureCell: CVTableViewCell {
    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var valueLabel: UILabel!
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
        setupAccessibility()
    }
    
    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        valueLabel.font = Appearance.Cell.Text.headTitleFont2
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
    }
    
    private func setupContent(row: CVRow) {
        dateLabel.text = row.accessoryText
        guard let keyFigure = row.associatedValue as? KeyFigure else { return }
        if let numberValue = Int(keyFigure.valueGlobalToDisplay) {
            let formatter: NumberFormatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale.current
            formatter.groupingSeparator = "common.thousandsSeparator".localized
            valueLabel.text = formatter.string(from: NSNumber(integerLiteral: numberValue))
        } else {
            valueLabel.text = keyFigure.valueGlobalToDisplay
        }
        valueLabel.textColor = keyFigure.color
        cvTitleLabel?.textColor = keyFigure.color
    }

    private func setupAccessibility() {
        accessibilityElements = [dateLabel,
                                 valueLabel,
                                 cvTitleLabel,
                                 cvSubtitleLabel].compactMap { $0 }
    }

}
