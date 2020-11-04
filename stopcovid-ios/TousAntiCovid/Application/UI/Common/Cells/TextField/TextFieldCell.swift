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
        setupUI(row: row)
        setupAccessibility()
    }
    
    private func trimText() {
        cvTextField.text = cvTextField.text?.trimmingCharacters(in: .whitespaces)
        currentAssociatedRow?.valueChanged?(cvTextField.text)
    }
    
    private func setupUI(row: CVRow) {
        cvTextField.delegate = self
        cvTextField.attributedPlaceholder = NSAttributedString(string: row.placeholder ?? "", attributes: [.foregroundColor: row.theme.placeholderColor])
        cvTextField.font = row.theme.subtitleFont()
        cvTextField.textColor = row.theme.subtitleColor
        cvTextField.keyboardType = row.textFieldKeyboardType ?? .default
        cvTextField.returnKeyType = row.textFieldReturnKeyType ?? .default
        cvTextField.textContentType = row.textFieldContentType ?? .none
        cvTextField.autocapitalizationType = row.textFieldCapitalizationType ?? .none
        cvTextField.tintColor = Asset.Colors.tint.color
        cvTextField.text = row.subtitle
        cvTextField.autocorrectionType = .no
        cvTextField.tag = row.associatedValue as? Int ?? 0
    }
    
    private func setupAccessibility() {
        accessibilityElements = [cvTextField].compactMap { $0 }
        cvTextField.accessibilityLabel = cvTitleLabel?.text
    }
    
    @IBAction func textFieldValueChanged() {
        let newText: String = cvTextField.text ?? ""
        let currentText: String = currentAssociatedRow?.subtitle ?? ""
        currentAssociatedRow?.subtitle = cvTextField.text
        currentAssociatedRow?.valueChanged?(cvTextField.text)
        if newText.count - currentText.count > 1 {
            textFieldDidEndOnExit()
        }
    }
    
    @IBAction func textFieldDidEndEditing() {
        trimText()
    }
    
    @IBAction func textFieldDidEndOnExit() {
        trimText()
        cvTextField.resignFirstResponder()
        currentAssociatedRow?.subtitle = cvTextField.text
        currentAssociatedRow?.didValidateValue?(cvTextField.text, self)
    }
    
}

extension TextFieldCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let regex = currentAssociatedRow?.textFieldRegex {
            guard !string.isEmpty else { return true }
            let currentText: String = textField.text ?? ""
            let range: Range<String.Index> = Range(range, in: currentText)!
            let updatedText: String = currentText.replacingCharacters(in: range, with: string.trimmingCharacters(in: .whitespaces))
            return updatedText ~= regex
        }
        return true
    }
    
}
