// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class KeyFiguresCell: CVTableViewCell {
    
    @IBOutlet private var button: UIButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var headerImageView: UIImageView!
    @IBOutlet private var updateLabel: UILabel!
    
    @IBOutlet private var titleLabels: [UILabel] = []
    @IBOutlet private var valueLabels: [UILabel] = []
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
        setupAccessibility()
    }
    
    private func setupUI() {
        updateLabel.text = "keyfigure.dailyUpdates".localized
        updateLabel.font = Appearance.Cell.Text.captionTitleFont
        updateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        cvTitleLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.contentHorizontalAlignment = .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        headerImageView.image = Asset.Images.compass.image
        headerImageView.tintColor = Asset.Colors.error.color
        headerLabel.textColor = Asset.Colors.error.color
        headerLabel.text = "home.infoSection.keyFigures".localized
        headerLabel.font = Appearance.Cell.Text.titleFont
        titleLabels.forEach { $0.font = Appearance.Cell.Text.valueTitleFont }
        valueLabels.forEach {
            $0.font = Appearance.Cell.Text.valueFont
            $0.textColor = Appearance.Cell.Text.titleColor
        }
    }
    
    private func setupContent(row: CVRow) {
        button.setTitle(row.buttonTitle, for: .normal)
        button.isHidden = row.buttonTitle == nil
        guard let keyFigures = row.associatedValue as? [KeyFigure] else { return }
        (0..<keyFigures.count).forEach { index in
            titleLabels[index].text = keyFigures[index].shortLabel
            titleLabels[index].textColor = keyFigures[index].color
            if let numberValue = Int(keyFigures[index].valueGlobalToDisplay) {
                let formatter: NumberFormatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.locale = Locale.current
                formatter.groupingSeparator = "common.thousandsSeparator".localized
                valueLabels[index].text = formatter.string(from: NSNumber(integerLiteral: numberValue))
            } else {
                valueLabels[index].text = keyFigures[index].valueGlobalToDisplay
            }
            
        }   
    }
    
    private func setupAccessibility() {
        accessibilityElements = ([headerLabel] + titleLabels + [button]).compactMap { $0 }
        (0..<titleLabels.count).forEach {
            titleLabels[$0].accessibilityLabel = "\(titleLabels[$0].text ?? "") \(valueLabels[$0].text ?? "")"
        }
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            contentView.layer.removeAllAnimations()
            contentView.alpha = 0.6
        } else {
            UIView.animate(withDuration: 0.3) {
                self.contentView.alpha = 1.0
            }
        }
    }
    
}
