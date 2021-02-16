// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LoadingCardCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 28/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class LoadingCardCell: CVTableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupAccessibility()
    }

    private func setupUI(with row: CVRow) {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        selectionStyle = .none
        accessoryType = .none
        containerView.layer.cornerRadius = 10.0
        containerView.layer.maskedCorners = row.theme.maskedCorners
        containerView.layer.masksToBounds = true
        activityIndicator.startAnimating()
        activityIndicator.color = .gray
        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
        }
    }

    private func setupAccessibility() {
        accessibilityElements = []
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
