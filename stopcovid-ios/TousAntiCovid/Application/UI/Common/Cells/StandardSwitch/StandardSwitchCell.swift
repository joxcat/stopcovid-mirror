// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StandardSwitchCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class StandardSwitchCell: CVTableViewCell {
    
    @IBOutlet var cvSwitch: UISwitch!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(row: row)
        setupAccessibility()
    }
    
    private func setupUI(row: CVRow) {
        cvSwitch.onTintColor = Appearance.Switch.onTint
        cvSwitch.isOn = row.isOn ?? false
    }
    
    private func setupAccessibility() {
        accessibilityElements = [cvSwitch].compactMap { $0 }
        cvSwitch.accessibilityLabel = cvTitleLabel?.text
    }
    
    @IBAction private func switchValueChanged() {
        currentAssociatedRow?.valueChanged?(cvSwitch.isOn)
    }
    
}
