// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickStateHeaderCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import UIKit

final class SickStateHeaderCell: CVTableViewCell {

    @IBOutlet private var topRightButton: UIButton!
    @IBOutlet private var bottomButton: UIButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var gradientView: GradientView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupTheme(row)
        setupContent(row)
        accessoryType = .none
        selectionStyle = .none
    }
    
    private func setupTheme(_ row: CVRow) {
        guard let isAtRisk = row.associatedValue as? Bool else { return }
        cvTitleLabel?.textColor = .white
        cvSubtitleLabel?.textColor = .white
        cvAccessoryLabel?.textColor = .white
        bottomButton.titleLabel?.font = Appearance.ShadowedButton.font
        bottomButton.tintColor = .white
        bottomButton.backgroundColor = isAtRisk ? Asset.Colors.notificationRiskButtonBackground.color : Asset.Colors.notificationButtonBackground.color
        bottomButton.layer.cornerRadius = 4.0
        bottomButton.layer.masksToBounds = false
        bottomButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        bottomButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        bottomButton.layer.shadowRadius = 4.0
        bottomButton.layer.shadowOpacity = 1.0
        topRightButton.tintColor = .white
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        gradientView.startColor = isAtRisk ? Asset.Colors.gradientStartRed.color : Asset.Colors.gradientStartGreen.color
        gradientView.endColor = isAtRisk ? Asset.Colors.gradientEndRed.color : Asset.Colors.gradientEndGreen.color
    }
    
    private func setupContent(_ row: CVRow) {
        if #available(iOS 13.0, *) {
            let imageAttachment: NSTextAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "info.circle.fill")?.withRenderingMode(.alwaysTemplate)
            let fullString: NSMutableAttributedString = NSMutableAttributedString(string: "\(row.buttonTitle ?? "") ")
            fullString.append(NSAttributedString(attachment: imageAttachment))
            bottomButton.setAttributedTitle(fullString, for: .normal)
        } else {
            bottomButton.setTitle(row.buttonTitle, for: .normal)
        }
    }
    
    @IBAction private func topRightButtonPressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
    @IBAction private func bottomButtonPressed(_ sender: Any) {
        currentAssociatedRow?.tertiarySelectionAction?()
    }
    
}
