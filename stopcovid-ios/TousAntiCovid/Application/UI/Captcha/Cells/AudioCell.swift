// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AudioCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class AudioCell: CVTableViewCell {

    @IBOutlet var button: UIButton!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        button.setImage(row.image, for: .normal)
        button.tintColor = Asset.Colors.tint.color
        accessoryType = .none
        selectionStyle = .none
    }
    
    @IBAction func didTouchButton(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
}
