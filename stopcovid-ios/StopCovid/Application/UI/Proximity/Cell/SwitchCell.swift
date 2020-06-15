// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SwitchCell.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 10/04/2020 - for the STOP-COVID project.
//

import UIKit

final class SwitchCell: CVTableViewCell {

    @IBOutlet var proximitySwitch: UISwitch!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        proximitySwitch.isOn = row.isOn == true
        proximitySwitch.onTintColor = Asset.Colors.tint.color
        cvTitleLabel?.alpha = row.enabled ? 1.0 : 0.3
        proximitySwitch.alpha = row.enabled ? 1.0 : 0.3
        isUserInteractionEnabled = row.enabled
    }
    
    @IBAction private func switchValueChanged() {
        currentAssociatedRow?.valueChanged?(proximitySwitch.isOn)
    }
    
}
