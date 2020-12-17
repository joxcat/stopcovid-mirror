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
    
    @IBOutlet weak var titleHeaderLabel: UILabel!
    @IBOutlet private var titleLabels: [UILabel] = []
    @IBOutlet private var valueLabels: [UILabel] = []

    @IBOutlet weak var valuesParentStackView: DynamicContentStackView!
    @IBOutlet weak var primaryValuesContainerStackView: DynamicContentStackView!
    @IBOutlet weak var secondaryValuesContainerStackView: DynamicContentStackView!
    @IBOutlet weak var secondaryStackView: UIStackView!
    @IBOutlet weak var titleHeaderSecondaryLabel: UILabel!
    @IBOutlet private var titleSecondaryLabels: [UILabel] = []
    @IBOutlet private var valueSecondaryLabels: [UILabel] = []
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
        setupAccessibility()
    }
    
    private func setupUI() {
        cvAccessoryLabel?.font = Appearance.Cell.Text.captionTitleFont
        cvAccessoryLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        button?.contentHorizontalAlignment = .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        headerImageView.image = Asset.Images.compass.image
        headerImageView.tintColor = Appearance.Cell.Text.errorColor
        headerLabel.textColor = Appearance.Cell.Text.errorColor
        headerLabel.font = Appearance.Cell.Text.titleFont
        titleHeaderLabel.text = "common.country.france".localized.uppercased()
        titleHeaderLabel.font = Appearance.Cell.Text.captionTitleFont2
        titleHeaderLabel.textColor = Appearance.Cell.Text.captionTitleColor
        titleHeaderSecondaryLabel.font = Appearance.Cell.Text.captionTitleFont2
        titleHeaderSecondaryLabel.textColor = Appearance.Cell.Text.captionTitleColor

        titleLabels.sorted { $0.tag < $1.tag }.forEach { $0.font = Appearance.Cell.Text.valueTitleFont }
        titleSecondaryLabels.sorted { $0.tag < $1.tag }.forEach { $0.font = Appearance.Cell.Text.valueTitleFont }
        valueLabels.sorted { $0.tag < $1.tag }.forEach {
            $0.font = Appearance.Cell.Text.valueFont
            $0.textColor = Appearance.Cell.Text.titleColor
        }
        valueSecondaryLabels.sorted { $0.tag < $1.tag }.forEach {
            $0.font = Appearance.Cell.Text.valueFont
            $0.textColor = Appearance.Cell.Text.titleColor
        }
        configureStackViews()
    }
    
    private func configureStackViews() {
        valuesParentStackView.threshold = UIStackView.thresholdCategorySize
        valuesParentStackView.thresholdAxis = valuesParentStackView.axis
        valuesParentStackView.thresholdAlignment = valuesParentStackView.alignment
        valuesParentStackView.thresholdSpacing = 30.0
        primaryValuesContainerStackView.threshold = UIStackView.thresholdCategorySize
        primaryValuesContainerStackView.thresholdAxis = .vertical
        primaryValuesContainerStackView.thresholdAlignment = .leading
        primaryValuesContainerStackView.thresholdSpacing = 10.0
        secondaryValuesContainerStackView.threshold = UIStackView.thresholdCategorySize
        secondaryValuesContainerStackView.thresholdAxis = .vertical
        secondaryValuesContainerStackView.thresholdAlignment = .leading
        secondaryValuesContainerStackView.thresholdSpacing = secondaryValuesContainerStackView.spacing
    }
    
    private func setupContent(row: CVRow) {
        headerLabel.text = row.title
        button.setTitle(row.buttonTitle, for: .normal)
        button.isHidden = row.buttonTitle == nil
        guard let keyFigures = row.associatedValue as? [KeyFigure] else { return }
        (0..<keyFigures.count).forEach { index in
            titleLabels[index].text = keyFigures[index].shortLabel
            titleLabels[index].textColor = keyFigures[index].color
            valueLabels[index].text = keyFigures[index].valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
        }
        let departmentKeyFigures: [KeyFigureDepartment?] = keyFigures.map { $0.currentDepartmentSpecificKeyFigure }
        let filteredDepartmentKeyFigures: [KeyFigureDepartment] = departmentKeyFigures.compactMap { $0 }
        let hideDepartmentKeyFigures: Bool = filteredDepartmentKeyFigures.isEmpty
        titleHeaderLabel.isHidden = hideDepartmentKeyFigures
        secondaryStackView.isHidden = hideDepartmentKeyFigures
        titleHeaderSecondaryLabel.text = filteredDepartmentKeyFigures.last?.label.uppercased()
        (0..<departmentKeyFigures.count).forEach { index in
            titleSecondaryLabels[index].text = keyFigures[index].shortLabel
            titleSecondaryLabels[index].textColor = keyFigures[index].color
            valueSecondaryLabels[index].text = departmentKeyFigures[index]?.valueToDisplay.formattingValueWithThousandsSeparatorIfPossible() ?? "-"
        }
    }
    
    private func setupAccessibility() {
        accessibilityElements = [headerLabel, cvAccessoryLabel].compactMap { $0 }
        if KeyFiguresManager.shared.displayDepartmentLevel && KeyFiguresManager.shared.currentPostalCode != nil {
            accessibilityElements?.append(titleHeaderSecondaryLabel!)
            accessibilityElements?.append(contentsOf: titleSecondaryLabels)
        }
        accessibilityElements?.append(titleHeaderLabel!)
        accessibilityElements?.append(contentsOf: titleLabels)
        accessibilityElements?.append(button!)
        
        (0..<titleLabels.count).forEach {
            let value: String = valueLabels[$0].text?.replacingOccurrences(of: " ", with: "").accessibilityNumberFormattedString() ?? ""
            let isValueAvailable: Bool = value != "-"
            titleLabels[$0].accessibilityLabel = "\(titleLabels[$0].text ?? ""), \(isValueAvailable ? value : "accessibility.keyFigures.noValueAvailable".localized)"
        }
        (0..<titleSecondaryLabels.count).forEach {
            let value: String = valueSecondaryLabels[$0].text?.replacingOccurrences(of: " ", with: "").accessibilityNumberFormattedString() ?? ""
            let isValueAvailable: Bool = value != "-"
            titleSecondaryLabels[$0].accessibilityLabel = "\(titleSecondaryLabels[$0].text ?? ""), \(isValueAvailable ? value : "accessibility.keyFigures.noValueAvailable".localized)"
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
