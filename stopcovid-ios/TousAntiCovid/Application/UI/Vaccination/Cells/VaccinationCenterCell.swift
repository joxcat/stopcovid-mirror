// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCenterCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class VaccinationCenterCell: CVTableViewCell, Xibbed {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var addressLabel: UILabel!
    @IBOutlet private var openingDateTitleLabel: UILabel!
    @IBOutlet private var openingDateLabel: UILabel!
    @IBOutlet private var openingTimeLabel: UILabel!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(row: row)
        setupContent(row: row)
        setupAccessibility(row: row)
    }

    private func setupUI(row: CVRow) {
        guard let vaccinationCenter = row.associatedValue as? VaccinationCenter else { return }
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        selectionStyle = .none
        accessoryType = .none
        addressLabel.font = Appearance.Cell.Text.subtitleFont
        addressLabel.textColor = Appearance.Cell.Text.subtitleColor
        openingDateTitleLabel.isHidden = vaccinationCenter.availabilityTimestamp == nil && (vaccinationCenter.planning ?? "").isEmpty
        openingDateTitleLabel.font = Appearance.Cell.Text.accessoryFont
        openingDateTitleLabel.textColor = Appearance.Cell.Text.captionTitleColor
        openingDateLabel.isHidden = vaccinationCenter.availabilityTimestamp == nil
        openingDateLabel?.textColor = Appearance.Cell.Text.titleColor
        openingDateLabel?.font = Appearance.Cell.Text.subtitleFont
        openingTimeLabel.isHidden = (vaccinationCenter.planning ?? "").isEmpty
        openingTimeLabel?.textColor = Appearance.Cell.Text.titleColor
        openingTimeLabel?.font = Appearance.Cell.Text.subtitleFont
        containerView.layer.cornerRadius = 10.0
        containerView.layer.maskedCorners = row.theme.maskedCorners
        containerView.layer.masksToBounds = true
    }

    private func setupContent(row: CVRow) {
        guard let vaccinationCenter = row.associatedValue as? VaccinationCenter else { return }
        cvTitleLabel?.text = vaccinationCenter.name
        cvSubtitleLabel?.text = vaccinationCenter.modalities
        addressLabel.text = getDisplayAddress(vaccinationCenter: vaccinationCenter)
        openingDateTitleLabel.text = "vaccinationCenterCell.openingDate.title".localized
        if let openingDate = vaccinationCenter.availabilityTimestamp {
            let date: Date = Date(timeIntervalSince1970: openingDate)
            openingDateLabel.text = "\("vaccinationCenterCell.openingDate.from".localized) \(date.shortDateFormatted())"
        }
        openingTimeLabel.text = vaccinationCenter.planning
    }

    private func getDisplayAddress(vaccinationCenter: VaccinationCenter) -> String {
        let firstLineAddress: String = [vaccinationCenter.streetNumber, vaccinationCenter.streetName].filter { !$0.isEmpty } .joined(separator: ", ")
        let secondLineAddress: String = [vaccinationCenter.postalCode, vaccinationCenter.locality].filter { !$0.isEmpty } .joined(separator: " ")
       return [firstLineAddress, secondLineAddress].filter { !$0.isEmpty } .joined(separator: "\n")
    }

    private func setupAccessibility(row: CVRow) {
        guard let vaccinationCenter = row.associatedValue as? VaccinationCenter else { return }
        accessibilityElements = [cvTitleLabel!, cvSubtitleLabel!, addressLabel!, openingDateTitleLabel!, openingDateLabel!]
        if let availabilityTimestamp = vaccinationCenter.availabilityTimestamp {
            let openingDate: Date = Date(timeIntervalSince1970: availabilityTimestamp)
            openingDateLabel.accessibilityLabel = openingDate.accessibilityRelativelyFormattedDate(prefixStringKey: "vaccinationCenterCell.openingDate.from")
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        guard currentAssociatedRow?.selectionAction != nil else { return }
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
