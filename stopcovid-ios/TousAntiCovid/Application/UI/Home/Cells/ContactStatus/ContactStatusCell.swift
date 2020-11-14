// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ContactStatusCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class ContactStatusCell: CVTableViewCell {
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var gradientView: GradientView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
    }
    
    private func setupUI() {
        cvTitleLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.accessoryFont
        cvAccessoryLabel?.font = Appearance.Cell.Text.accessoryFont
        cvAccessoryLabel?.textColor = .white
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
    }
    
    private func setupContent(row: CVRow) {
        guard let gradientColors = row.associatedValue as? (startColor: UIColor, endColor: UIColor) else { return }
        gradientView.startColor = gradientColors.startColor
        gradientView.endColor = gradientColors.endColor
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
