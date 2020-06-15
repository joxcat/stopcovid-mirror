// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickStateHeaderCell.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the STOP-COVID project.
//

import UIKit

final class SickStateHeaderCell: CVTableViewCell {

    @IBOutlet private var topRightButton: UIButton!
    @IBOutlet private var bottomButton: UIButton!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupTheme()
        bottomButton.setTitle(row.buttonTitle, for: .normal)
        accessoryType = .none
        selectionStyle = .none
    }
    
    private func setupTheme() {
        cvAccessoryLabel?.textColor = Appearance.Cell.Text.titleColor
        bottomButton.titleLabel?.font = Appearance.Cell.Text.standardFont
        bottomButton.tintColor = Appearance.Button.Tertiary.titleColor
        topRightButton.tintColor = Appearance.Button.Tertiary.titleColor
    }
    
    @IBAction private func topRightButtonPressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
    @IBAction private func bottomButtonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
}
