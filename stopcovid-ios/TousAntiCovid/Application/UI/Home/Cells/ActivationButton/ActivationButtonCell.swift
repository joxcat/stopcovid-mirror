// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ActivationButtonCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class ActivationButtonCell: CVTableViewCell {

    @IBOutlet var button: CVButton!
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        UIView.performWithoutAnimation {
            self.button?.setTitle(row.title, for: .normal)
            self.button?.layoutIfNeeded()
        }
        button?.accessibilityLabel = row.title?.removingEmojis()
        button?.accessibilityHint = nil
        button?.buttonStyle = row.theme.buttonStyle
        button.alpha = row.enabled ? 1.0 : 0.3
        isUserInteractionEnabled = row.enabled
        accessoryType = .none
        selectionStyle = .none
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
    }
    
    @IBAction func didTouchButton(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
}
