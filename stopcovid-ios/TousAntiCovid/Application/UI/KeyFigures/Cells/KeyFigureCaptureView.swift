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

final class KeyFigureCaptureView: UIView, Xibbed {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var valueLabel: UILabel!
    @IBOutlet private var departmentLabel: UILabel!
    
    @IBOutlet private var countryStackView: UIStackView!
    @IBOutlet private var countryLabel: UILabel!
    @IBOutlet private var countryValueLabel: UILabel!
    @IBOutlet private var valuesContainerStackView: DynamicContentStackView!
    
    static func captureKeyFigure(_ keyFigure: KeyFigure) -> UIImage {
        let view: KeyFigureCaptureView = KeyFigureCaptureView.instantiate()
        view.setup(with: keyFigure)
        let containerView: UIView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 335.0, height: 300.0))
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0.0).isActive = true
        view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0.0).isActive = true
        view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0.0).isActive = true
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
        containerView.frame.size.height = view.frame.height
        let capture: UIImage = containerView.screenshot()!
        return capture
    }
    
    private func setup(with keyFigure: KeyFigure) {
        setupUI(with: keyFigure)
        setupContent(with: keyFigure)
    }
    
    private func setupUI(with keyFigure: KeyFigure) {
        backgroundColor = Appearance.Cell.cardBackgroundColor
        titleLabel.font = Appearance.Cell.Text.titleFont
        titleLabel.textColor = keyFigure.color
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        departmentLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        departmentLabel?.font = Appearance.Cell.Text.captionTitleFont2
        countryLabel?.textColor = Appearance.Cell.Text.captionTitleColor
        countryLabel?.font = Appearance.Cell.Text.captionTitleFont2
        countryValueLabel?.font = Appearance.Cell.Text.titleFontExtraBold
        countryValueLabel?.textColor = keyFigure.color
        valueLabel.font = Appearance.Cell.Text.headTitleFont2
        valueLabel.textColor = keyFigure.color
    }
    
    private func setupContent(with keyFigure: KeyFigure) {
        titleLabel.text = keyFigure.label
        if let departmentKeyFigure = keyFigure.currentDepartmentSpecificKeyFigure {
            dateLabel.text = departmentKeyFigure.formattedDate
            departmentLabel?.text = departmentKeyFigure.label.uppercased()
            departmentLabel?.isHidden = false
            valueLabel.text = departmentKeyFigure.valueToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            countryLabel?.text = "france".localized.uppercased()
            countryValueLabel.text = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
            countryStackView?.isHidden = false
        } else {
            dateLabel.text = keyFigure.formattedDate
            if KeyFiguresManager.shared.currentFormattedDepartmentNameAndPostalCode == nil || keyFigure.category == .app {
                departmentLabel?.isHidden = true
            } else {
                departmentLabel?.text = "common.country.france".localized.uppercased()
                departmentLabel?.isHidden = false
            }
            countryStackView?.isHidden = true
            valueLabel.text = keyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible()
        }
    }

}
