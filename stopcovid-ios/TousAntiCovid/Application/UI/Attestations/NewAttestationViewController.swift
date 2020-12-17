// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NewAttestationViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import PKHUD

final class NewAttestationViewController: CVTableViewController {
    
    private let didTouchSelectFieldItem: (_ items: [AttestationFormFieldItem], _ selectedItem: AttestationFormFieldItem?, _ didSelectedFieldItem: @escaping (_ fieldValue: AttestationFormFieldItem) -> ()) -> ()
    private let deinitBlock: () -> ()
    
    private let groupedFields: [[AttestationFormField]] = AttestationsManager.shared.formFields
    private var isFirstLoad: Bool = true
    private weak var firstTextField: UITextField?
    private var fieldValues: [String: String] = [:]
    private var fieldSelectedItems: [String: AttestationFormFieldItem] = [:]
    private var dobDate: Date = Date().dateByAddingYears(-18)
    private var outingDate: Date = Date()
    private var currentSaveMyData: Bool = false
    
    @UserDefault(key: .saveAttestationFieldsData)
    private var saveMyData: Bool = false
    
    init(didTouchSelectFieldItem: @escaping (_ items: [AttestationFormFieldItem], _ selectedItem: AttestationFormFieldItem?, _ didSelectedFieldItem: @escaping (_ fieldValue: AttestationFormFieldItem) -> ()) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchSelectFieldItem = didTouchSelectFieldItem
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "newAttestationController.title".localized
        initUI()
        preloadFieldValues()
        reloadUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            focusRightField()
        }
    }
    
    deinit {
        deinitBlock()
    }
    
    private func initUI() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.keyboardDismissMode = .onDrag
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.cancel".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "newAttestationController.generate".localized, style: .plain, target: self, action: #selector(didTouchGenerateButton))
    }
    
    private func focusRightField() {
        if AttestationsManager.shared.getAttestationFieldValues().isEmpty {
            firstTextField?.becomeFirstResponder()
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true)
    }
    
    @objc private func didTouchGenerateButton() {
        if areFieldsValid() {
            showGenerateAlert()
        } else {
            showAlert(title: "newAttestationController.missingInfo.alert.title".localized,
                      message: "newAttestationController.missingInfo.alert.message".localized,
                      okTitle: "common.ok".localized)
        }
    }

    private func preloadFieldValues() {
        fieldValues = AttestationsManager.shared.getAttestationFieldValues()
        let now: Date = Date()
        let day: String = now.dayMonthYearFormatted()
        let hour: String = now.shortTimeFormatted()
        fieldValues["datetime"] = "\(day), \(hour)"
        fieldValues["datetime-day"] = day
        fieldValues["datetime-hour"] = hour
        if let dobTimestampString = fieldValues["dob-timestamp"], let dobTimestamp = Double(dobTimestampString) {
            dobDate = Date(timeIntervalSince1970: Double(dobTimestamp))
        }
        currentSaveMyData = saveMyData
    }

    private func areFieldsValid() -> Bool {
        var areAllFieldsFilledIn: Bool = true
        groupedFields.joined().forEach { field in
            if fieldValues[field.key] == nil {
                areAllFieldsFilledIn = false
            }
        }
        return areAllFieldsFilledIn
    }

    private func showGenerateAlert() {
        showAlert(title: "newAttestationController.generate.alert.title".localized,
                  message: "newAttestationController.generate.alert.message".localized,
                  okTitle: "newAttestationController.generate.alert.validate".localized,
                  cancelTitle: "common.cancel".localized, handler: { [weak self] in
                    self?.generate()
                  })
    }

    private func generate() {
        HUD.show(.progress)
        DispatchQueue.main.async {
            let now: Date = Date()
            self.fieldValues["creationDate"] = now.dayMonthYearFormatted()
            self.fieldValues["creationHour"] = now.shortTimeFormatted()
            guard let qrCodeString = AttestationsManager.shared.generateQRCode(for: self.fieldValues) else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCode = qrCodeString.qrCode() else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCodeData = UIGraphicsImageRenderer(size: qrCode.size, format: qrCode.imageRendererFormat).image(actions: { _ in
                UIImage(ciImage: qrCode.ciImage!).draw(in: CGRect(origin: .zero, size: qrCode.size))
            }).pngData() else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCodeDisplayableString = AttestationsManager.shared.generateQRCodeDisplayableString(for: self.fieldValues) else {
                self.showGenerationErrorAlert()
                return
            }
            guard let qrCodeFooter = AttestationsManager.shared.generateQRCodeFooter(for: self.fieldValues) else {
                self.showGenerationErrorAlert()
                return
            }
            AttestationsManager.shared.saveAttestation(timestamp: Int(self.outingDate.timeIntervalSince1970), qrCode: qrCodeData, footer: qrCodeFooter, qrCodeString: qrCodeDisplayableString, reason: self.fieldValues["reason-code"] ?? "")
            self.saveFieldValuesIfNeeded()
            HUD.hide()
            self.dismiss(animated: true)
        }
    }
    
    private func showGenerationErrorAlert() {
        showAlert(title: "newAttestationController.generate.error.alert.title".localized,
                  message: "newAttestationController.generate.error.alert.message".localized,
                  okTitle: "common.ok".localized)
    }
    
    private func saveFieldValuesIfNeeded() {
        guard currentSaveMyData else { return }
        saveMyData = currentSaveMyData
        fieldValues.forEach { key, value in
            guard !key.contains("datetime") && !key.contains("reason") && !key.contains("creationDate") && !key.contains("creationHour") else { return }
            AttestationsManager.shared.saveAttestationFieldValueForKey(key, value: value)
        }
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        
        let headerText: String = "newAttestationController.header".localizedOrEmpty
        if headerText.isEmpty {
            rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: true))
        } else {
            let headerRow: CVRow = CVRow(title: headerText,
                                         xibName: .textCell,
                                         theme:  CVRow.Theme(topInset: 20.0,
                                                             bottomInset: 20.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.footerFont },
                                                             titleColor: Appearance.Cell.Text.captionTitleColor,
                                                             separatorLeftInset: 0.0,
                                                             separatorRightInset: 0.0))
            rows.append(headerRow)
        }
        
        let theme: CVRow.Theme = CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                             topInset: 10.0,
                                             bottomInset: 10.0,
                                             textAlignment: .natural,
                                             titleFont: { .regular(size: 12.0) },
                                             titleColor: Appearance.Cell.Text.subtitleColor,
                                             subtitleFont: { .regular(size: 17.0) },
                                             subtitleColor: Appearance.Cell.Text.titleColor,
                                             separatorLeftInset: Appearance.Cell.leftMargin)
        
        var fieldTag: Int = 1000
        let fieldsRows: [[CVRow]] = groupedFields.map { fields in
            var rows: [CVRow] = fields.map { field in
                let row: CVRow
                switch field.type {
                case .date:
                    row = CVRow(title: field.name,
                                subtitle: fieldValues[field.key],
                                placeholder: field.placeholder,
                                xibName: .dateCell,
                                theme: self.defaultRowTheme(),
                                associatedValue: fieldTag,
                                maximumDate: field.key == "dob" ? Date() : nil,
                                initialDate: field.key == "dob" ? dobDate : nil,
                                datePickerMode: .date,
                                willDisplay: { [weak self] cell in
                                    guard let self = self else { return }
                                    (cell as? DateCell)?.datePicker.date = self.dobDate
                                    (cell as? DateCell)?.cvSubtitleLabel?.text = self.fieldValues[field.key]
                                },
                                valueChanged: { [weak self] value in
                                    guard let value = value as? Date else { return }
                                    self?.fieldValues["\(field.key)-timestamp"] = "\(value.timeIntervalSince1970)"
                                    self?.fieldValues[field.key] = value.dayMonthYearFormatted()
                                }, displayValueForValue: { value -> String? in
                                    guard let value = value as? Date else { return nil }
                                    return value.dayMonthYearFormatted()
                                })
                case .dateTime:
                    row = CVRow(title: field.name,
                                subtitle: fieldValues[field.key],
                                placeholder: field.placeholder,
                                xibName: .dateCell,
                                theme: self.defaultRowTheme(),
                                associatedValue: fieldTag,
                                minimumDate: field.key == "datetime" ? Date() : nil,
                                initialDate: field.key == "datetime" ? Date() : nil,
                                datePickerMode: .dateAndTime,
                                willDisplay: { [weak self] cell in
                                    guard let self = self else { return }
                                    (cell as? DateCell)?.datePicker.date = self.outingDate
                                    (cell as? DateCell)?.cvSubtitleLabel?.text = self.fieldValues[field.key]
                                },
                                valueChanged: { [weak self] value in
                                    guard let value = value as? Date else { return }
                                    if field.key == "datetime" {
                                        self?.outingDate = value
                                    }
                                    let day: String = value.dayMonthYearFormatted()
                                    let hour: String = value.shortTimeFormatted()
                                    self?.fieldValues["\(field.key)-timestamp"] = "\(value.timeIntervalSince1970)"
                                    self?.fieldValues["\(field.key)"] = "\(day), \(hour)"
                                    self?.fieldValues["\(field.key)-day"] = day
                                    self?.fieldValues["\(field.key)-hour"] = hour
                                }, displayValueForValue: { value -> String? in
                                    guard let value = value as? Date else { return nil }
                                    return "\(value.dayMonthYearFormatted()), \(value.shortTimeFormatted())"
                                })
                case .list:
                    let selectedListItem: AttestationFormFieldItem? = fieldSelectedItems[field.key]
                    row = CVRow(title: field.name,
                                subtitle: selectedListItem?.shortLabel ?? "-",
                                xibName: .textCell,
                                theme: self.listRowTheme(fieldKey: field.key),
                                selectionAction: { [weak self] in
                                    self?.didTouchSelectFieldItem(field.items ?? [], self?.fieldSelectedItems[field.key]) { selectedItem in
                                        self?.fieldSelectedItems[field.key] = selectedItem
                                        self?.fieldValues["\(field.key)"] = selectedItem.code
                                        self?.fieldValues["\(field.key)-code"] = selectedItem.code
                                        self?.fieldValues["\(field.key)-shortlabel"] = selectedItem.shortLabel
                                        self?.reloadUI()
                                    }
                                })
                default:
                    row = CVRow(title: field.name,
                                subtitle: fieldValues[field.key],
                                placeholder: field.placeholder,
                                xibName: .standardTextFieldCell,
                                theme: self.defaultRowTheme(),
                                associatedValue: fieldTag,
                                textFieldKeyboardType: field.type.keyboardType,
                                textFieldContentType: field.contentType?.textContentType,
                                textFieldCapitalizationType: field.type.capitalizationType,
                                textFieldRegex: field.key == "zip" ? "^[0-9]{0,5}$" : nil,
                                willDisplay: { [weak self] cell in
                                    guard let self = self else { return }
                                    if self.firstTextField == nil {
                                        self.firstTextField = (cell as? StandardTextFieldCell)?.cvTextField
                                    }
                                    (cell as? StandardTextFieldCell)?.cvTextField.text = self.fieldValues[field.key]
                                }, valueChanged: { [weak self] value in
                                    let valueString: String = value as? String ?? ""
                                    self?.fieldValues[field.key] = valueString.isEmpty ? nil : valueString
                                }, didValidateValue: { [weak self] _, cell in
                                    guard let fieldTag = (cell as? StandardTextFieldCell)?.cvTextField.tag else { return }
                                    self?.tableView.viewWithTag(fieldTag + 1)?.becomeFirstResponder()
                                })
                }
                fieldTag += 1
                return row
            }
            if let lastRow = rows.last {
                var theme: CVRow.Theme = theme
                theme.separatorLeftInset = 0.0
                var row: CVRow = lastRow
                row.theme = theme
                rows.removeLast()
                rows.append(row)
            }
            rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: true))
            return rows
        }
        rows.append(contentsOf: fieldsRows.joined())
        let switchRow: CVRow = CVRow(title: "newAttestationController.saveMyData".localized,
                                     isOn: currentSaveMyData,
                                     xibName: .standardSwitchCell,
                                     theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                        topInset: 10.0,
                                                        bottomInset: 10.0,
                                                        textAlignment: .left,
                                                        titleFont: { Appearance.Cell.Text.standardFont },
                                                        separatorLeftInset: 0.0,
                                                        separatorRightInset: 0.0),
                                     willDisplay: { [weak self] cell in
                                        guard let self = self else { return }
                                        (cell as? StandardSwitchCell)?.cvSwitch.isOn = self.currentSaveMyData
                                     }, valueChanged: { [weak self] value in
                                        guard let isOn = value as? Bool else { return }
                                        self?.currentSaveMyData = isOn
                                     })
        rows.append(switchRow)
        let footerRow: CVRow = CVRow(title: "newAttestationController.footer".localized,
                                     xibName: .textCell,
                                     theme:  CVRow.Theme(topInset: 20.0,
                                                         bottomInset: 0.0,
                                                         textAlignment: .natural,
                                                         titleFont: { Appearance.Cell.Text.footerFont },
                                                         titleColor: Appearance.Cell.Text.captionTitleColor))
        rows.append(footerRow)
        return rows
    }
    
    private func defaultRowTheme() -> CVRow.Theme {
        return CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                           topInset: 10.0,
                           bottomInset: 10.0,
                           textAlignment: .natural,
                           titleFont: { .regular(size: 12.0) },
                           titleColor: Appearance.Cell.Text.subtitleColor,
                           subtitleFont: { .regular(size: 17.0) },
                           subtitleColor: Appearance.Cell.Text.titleColor,
                           separatorLeftInset: Appearance.Cell.leftMargin)
    }
    
    private func listRowTheme(fieldKey: String) -> CVRow.Theme {
        return CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                           topInset: 10.0,
                           bottomInset: 10.0,
                           textAlignment: .natural,
                           titleFont: { .regular(size: 12.0) },
                           titleColor: Appearance.Cell.Text.subtitleColor,
                           subtitleFont: { .regular(size: 17.0) },
                           subtitleColor: fieldSelectedItems[fieldKey] == nil ? Appearance.Cell.Text.placeholderColor : Appearance.Cell.Text.subtitleColor,
                           separatorLeftInset: Appearance.Cell.leftMargin)
    }
    
}
