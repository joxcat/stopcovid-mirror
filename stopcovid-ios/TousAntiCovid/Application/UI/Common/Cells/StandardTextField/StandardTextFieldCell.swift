// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StandardTextFieldCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/05/2020 - for the TousAntiCovid project.
//


import UIKit

final class StandardTextFieldCell: TextFieldCell {

    override func setup(with row: CVRow) {
        super.setup(with: row)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: true)
        if highlighted {
            cvTextField.becomeFirstResponder()
        }
    }

}
