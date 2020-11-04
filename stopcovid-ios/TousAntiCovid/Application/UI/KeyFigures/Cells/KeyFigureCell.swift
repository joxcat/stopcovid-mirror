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
    @IBOutlet private var departmentLabel: UILabel!
    @IBOutlet private var containerView: UIView!
    
    @IBOutlet private var countryStackView: UIStackView!
    @IBOutlet private var countryLabel: UILabel!
    @IBOutlet private var countryValueLabel: UILabel!
    
    @IBOutlet private var mainTrendImageView: UIImageView!
    @IBOutlet private var countryTrendImageView: UIImageView!
    @IBOutlet private var sharingImageView: UIImageView!
    
    @IBOutlet private var valuesContainerStackView: DynamicContentStackView!
    @IBOutlet private var sharingButton: UIButton!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
        setupAccessibility(row: row)
    }

    override func capture() -> UIImage? {
        sharingImageView.isHidden = true
        let image: UIImage? = containerView.screenshot()
        sharingImageView.isHidden = false
        return image
    }

    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        valuesContainerStackView.threshold = .accessibilityMedium
        valuesContainerStackView.thresholdAxis = .vertical
        valuesContainerStackView.thresholdAlignment = .leading
        valuesContainerStackView.thresholdSpacing = 20.0
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        departmentLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        departmentLabel?.font = Appearance.Cell.Text.captionTitleFont2
        countryLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        countryLabel?.font = Appearance.Cell.Text.captionTitleFont2
        countryValueLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        valueLabel.font = Appearance.Cell.Text.headTitleFont2
        sharingImageView.tintColor = Appearance.tintColor
        sharingImageView.image = Asset.Images.shareIcon.image
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
    }
    
    private func setupContent(row: CVRow) {
        dateLabel.text = row.accessoryText
        guard let keyFigure = row.associatedValue as? KeyFigure else { return }
        valueLabel.textColor = keyFigure.color
        cvTitleLabel?.textColor = keyFigure.color
        countryValueLabel?.textColor = keyFigure.color
        if let departmentKeyFigure = keyFigure.currentDepartmentSpecificKeyFigure {
            departmentLabel?.text = KeyFiguresManager.shared.currentDepartmentName?.uppercased()
            departmentLabel?.isHidden = false
            valueLabel.text = departmentKeyFigure.valueToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            countryLabel?.text = "france".localized.uppercased()
            countryValueLabel.text = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            countryStackView?.isHidden = false
            mainTrendImageView.image = departmentKeyFigure.trend?.image
            mainTrendImageView.isHidden = departmentKeyFigure.trend?.image == nil
            countryTrendImageView.image = keyFigure.trend?.image
            countryTrendImageView.isHidden = keyFigure.trend?.image == nil
        } else {
            if KeyFiguresManager.shared.currentFormattedDepartmentNameAndPostalCode == nil || keyFigure.category == .app {
                departmentLabel?.isHidden = true
            } else {
                departmentLabel?.text = "common.country.france".localized.uppercased()
                departmentLabel?.isHidden = false
            }
            mainTrendImageView.image = keyFigure.trend?.image
            mainTrendImageView.isHidden = keyFigure.trend?.image == nil
            countryStackView?.isHidden = true
            valueLabel.text = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
        }
    }
    
    private func setupAccessibility(row: CVRow) {
        guard let keyFigure = row.associatedValue as? KeyFigure else { return }
        accessibilityElements = [dateLabel!]
        if !departmentLabel.isHidden {
            accessibilityElements?.append(departmentLabel!)
        }
        accessibilityElements?.append(cvTitleLabel!)
        if !countryStackView.isHidden {
            accessibilityElements?.append(countryLabel!)
            let countryValue: String = countryValueLabel.text?.replacingOccurrences(of: " ", with: "") ?? ""
            countryLabel?.accessibilityLabel = "\(countryLabel?.text ?? ""), \(countryValue), \(keyFigure.trend?.accessibilityLabel ?? "")"
        }
        accessibilityElements?.append(cvSubtitleLabel!)
        accessibilityElements?.append(sharingButton!)
        let value: String = valueLabel.text?.replacingOccurrences(of: " ", with: "").accessibilityNumberFormattedString() ?? ""
        let trendString: String = (keyFigure.currentDepartmentSpecificKeyFigure == nil ? keyFigure.trend?.accessibilityLabel : keyFigure.currentDepartmentSpecificKeyFigure?.trend?.accessibilityLabel) ?? ""
        cvTitleLabel?.accessibilityLabel = "\(cvTitleLabel?.text ?? ""), \(value), \(trendString)"
        sharingButton.accessibilityLabel = "accessibility.hint.keyFigure.share".localized
        let date: Date = Date(timeIntervalSince1970: Double(keyFigure.lastUpdate))
        dateLabel.accessibilityLabel = date.accessibilityRelativelyFormattedDate(prefixStringKey: "keyFigures.update")
    }
    
    @IBAction private func didTouchSharingButton(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }

}
