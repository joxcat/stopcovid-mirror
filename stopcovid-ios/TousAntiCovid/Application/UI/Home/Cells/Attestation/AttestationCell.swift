// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class AttestationCell: CVTableViewCell {
    
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
    }
    
    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        cvTitleLabel?.font = Appearance.Cell.Text.titleFont
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
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
