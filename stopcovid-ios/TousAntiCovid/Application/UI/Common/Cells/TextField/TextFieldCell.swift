// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  TextFieldCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

class TextFieldCell: CVTableViewCell {
    
    @IBOutlet var cvTextField: UITextField!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        cvTextField.attributedPlaceholder = NSAttributedString(string: row.placeholder ?? "", attributes: [.foregroundColor: row.theme.placeholderColor])
        cvTextField.font = row.theme.subtitleFont()
        cvTextField.textColor = row.theme.subtitleColor
        cvTextField.keyboardType = row.textFieldKeyboardType ?? .default
        cvTextField.returnKeyType = row.textFieldReturnKeyType ?? .default
        cvTextField.tintColor = Asset.Colors.tint.color
        cvTextField.text = row.subtitle
        cvTextField.autocorrectionType = .no
    }
    
    @IBAction private func textFieldValueChanged() {
        currentAssociatedRow?.valueChanged?(cvTextField.text)
    }
    
    @IBAction private func textFieldDidEndOnExit() {
        currentAssociatedRow?.didValidateValue?(cvTextField.text)
    }
    
}
