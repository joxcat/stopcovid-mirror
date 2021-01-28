// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DateCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/05/2020 - for the TousAntiCovid project.
//


import UIKit

final class DateCell: TextFieldCell {

    let datePicker: UIDatePicker = UIDatePicker()
    let toolbar: UIToolbar = UIToolbar()
    
    deinit {
        print("\(type(of: self)) deallocated")
    }
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(row: row)
        setupAccessibility()
    }
    
    private func setupUI(row: CVRow) {
        cvTextField.text = nil
        cvSubtitleLabel?.isHidden = false
        updateSubtitle(with: row.subtitle)
        cvTextField.tintColor = .clear
        datePicker.datePickerMode = row.datePickerMode ?? .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.minimumDate = row.minimumDate
        datePicker.maximumDate = row.maximumDate
        datePicker.date = row.initialDate ?? Date()
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        cvTextField.inputView = datePicker
        toolbar.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: 44.0)
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                         UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))]
        toolbar.items?.forEach { $0.tintColor = Appearance.tintColor }
        cvTextField.inputAccessoryView = toolbar
    }
    
    private func updateSubtitle(with text: String?) {
        cvTextField.alpha = text?.isEmpty == false ? 0.0 : 1.0
        cvSubtitleLabel?.text = text
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: true)
        if highlighted {
            cvTextField.becomeFirstResponder()
        }
    }
    
    private func setupAccessibility() {
        accessibilityElements = [cvTitleLabel, cvSubtitleLabel].compactMap { $0 }
    }
    
    @objc private func doneButtonPressed() {
        cvTextField.resignFirstResponder()
        datePickerValueChanged()
        currentAssociatedRow?.didValidateValue?(datePicker.date, self)
    }
    
    @objc private func datePickerValueChanged() {
        currentAssociatedRow?.valueChanged?(datePicker.date)
        updateSubtitle(with: currentAssociatedRow?.displayValueForValue?(datePicker.date))
    }

    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }

}
