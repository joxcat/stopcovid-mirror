// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NewPostalCodeCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class NewPostalCodeCell: CVTableViewCell {

    @IBOutlet private var button: UIButton!
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
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.contentHorizontalAlignment = .center
        button?.tintColor = Appearance.Button.Primary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
    }

    private func setupContent(row: CVRow) {
        button.setTitle(row.buttonTitle, for: .normal)
        button.isHidden = row.buttonTitle == nil
    }

    private func setupAccessibility() {
        accessibilityElements = [cvTitleLabel,
                                 cvSubtitleLabel,
                                 button].compactMap { $0 }
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
