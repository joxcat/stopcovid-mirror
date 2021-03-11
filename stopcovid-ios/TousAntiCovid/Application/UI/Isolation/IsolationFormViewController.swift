// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  IsolationFormViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/12/2020 - for the TousAntiCovid project.
//

import UIKit

final class IsolationFormViewController: CVTableViewController {
    
    let deinitBlock: () -> ()
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        
        let headerText: String = "isolationFormController.header.title".localizedOrEmpty
        if headerText.isEmpty {
            rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
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
        
        rows.append(contentsOf: stateRows())
        guard let state = IsolationManager.shared.currentState else { return rows }
        switch state {
        case .contactCase:
            rows.append(contentsOf: contactCaseRows())
        case .positiveCase:
            rows.append(contentsOf: positiveCaseRows())
        default:
            break
        }
        if IsolationManager.shared.currentRecommendationState != .indeterminate {
            rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
            rows.append(readRecommendationsRow())
        } else {
            let footerText: String = "isolationFormController.footer.title".localizedOrEmpty
            if footerText.isEmpty {
                rows.append(.emptyFor(topInset: 0.0, bottomInset: 0.0, showSeparator: false))
            } else {
                let footerRow: CVRow = CVRow(title: footerText,
                                             xibName: .textCell,
                                             theme:  CVRow.Theme(topInset: 20.0,
                                                                 bottomInset: 0.0,
                                                                 textAlignment: .natural,
                                                                 titleFont: { Appearance.Cell.Text.footerFont },
                                                                 titleColor: Appearance.Cell.Text.captionTitleColor,
                                                                 separatorLeftInset: 0.0,
                                                                 separatorRightInset: 0.0))
                rows.append(footerRow)
            }
        }
        return rows
    }
    
    override func reloadUI(animated: Bool = false, completion: (() -> ())? = nil) {
        super.reloadUI(animated: animated) { [weak self] in
            self?.scrollToBottomIfNeeded()
            completion?()
        }
    }
    
    private func initUI() {
        title = "isolationFormController.title".localized
        tableView.contentInset.top = 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.tintColor = Appearance.tintColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    private func scrollToBottomIfNeeded() {
        if tableView.contentSize.height > tableView.frame.height {
            tableView.scrollToRow(at: IndexPath(row: rows.count - 1, section: 0), at: .top, animated: true)
        }
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        IsolationManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        IsolationManager.shared.removeObserver(self)
    }
    
}

extension IsolationFormViewController {
    
    private func stateRows() -> [CVRow] {
        var rows: [CVRow] = [sectionRow(title: "isolationFormController.state.sectionTitle".localized)]
        rows.append(selectableRow(title: "isolationFormController.state.allGood".localized,
                                  isSelected: IsolationManager.shared.currentState == .allGood,
                                  isLastRowInGroup: false,
                                  selectionBlock: { IsolationManager.shared.updateState(.allGood) }))
        rows.append(selectableRow(title: "isolationFormController.state.symptoms".localized,
                                  isSelected: IsolationManager.shared.currentState == .symptoms,
                                  isLastRowInGroup: false,
                                  selectionBlock: { [weak self] in
                                    guard let self = self else { return }
                                    IsolationManager.shared.showSymptomsAlert(on: self) {
                                        IsolationManager.shared.updateState(.symptoms)
                                    }
                                  }))
        rows.append(selectableRow(title: "isolationFormController.state.contactCase".localized,
                                  isSelected: IsolationManager.shared.currentState == .contactCase,
                                  isLastRowInGroup: false,
                                  selectionBlock: { IsolationManager.shared.updateState(.contactCase) }))
        rows.append(selectableRow(title: "isolationFormController.state.positiveCase".localized,
                                  isSelected: IsolationManager.shared.currentState == .positiveCase,
                                  isLastRowInGroup: true,
                                  selectionBlock: { IsolationManager.shared.updateState(.positiveCase) }))
        return rows
    }
    
    private func contactCaseRows() -> [CVRow] {
        var rows: [CVRow] = []
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: true))
        rows.append(lastContactDateRow())
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
        
        rows.append(contentsOf: yesNoQuestionRows(title: "isolationFormController.contactCase.index.sectionTitle".localized,
                                                  isAnswerYes: IsolationManager.shared.isolationIsKnownIndexAtHome,
                                                  answerBlock: { isAnswerYes in IsolationManager.shared.setIsKnownIndexAtHome(isAnswerYes) }))
        
        guard IsolationManager.shared.isolationIsKnownIndexAtHome == true else { return rows }
        guard IsolationManager.shared.isolationIsTestNegative != nil else { return rows }
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
        rows.append(contentsOf: yesNoQuestionRows(title: "isolationFormController.contactCase.haveIndexSymptomsEndDate.sectionTitle".localized,
                                                  isAnswerYes: IsolationManager.shared.isolationKnowsIndexSymptomsEndDate,
                                                  answerBlock: { isAnswerYes in IsolationManager.shared.setKnowsIndexSymptomsEndDate(isAnswerYes) }))
        
        guard IsolationManager.shared.isolationKnowsIndexSymptomsEndDate == true else { return rows }
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
        rows.append(sectionRow(title: "isolationFormController.contactCase.symptomsEndDate.sectionTitle".localized))
        rows.append(indexSymptomsEndDateRow())
        return rows
    }
    
    private func positiveCaseRows() -> [CVRow] {
        var rows: [CVRow] = []
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: true))
        rows.append(positiveTestDateRow())
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
        
        rows.append(contentsOf: yesNoQuestionRows(title: "isolationFormController.positiveCase.haveSymptoms.sectionTitle".localized,
                                                  isAnswerYes: IsolationManager.shared.isolationIsHavingSymptoms,
                                                  answerBlock: { isAnswerYes in IsolationManager.shared.setIsHavingSymptoms(isAnswerYes) }))
        
        guard IsolationManager.shared.isolationIsHavingSymptoms == true else { return rows }
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
        rows.append(symptomsStartDateRow())
        
        guard IsolationManager.shared.isPositiveCaseIsolationEnded == true else { return rows }
        rows.append(.emptyFor(topInset: 10.0, bottomInset: 10.0, showSeparator: false))
        rows.append(contentsOf: yesNoQuestionRows(title: "isolationFormController.positiveCase.stillHavingFever.sectionTitle".localized,
                                                  isAnswerYes: IsolationManager.shared.isolationIsStillHavingFever,
                                                  answerBlock: { isAnswerYes in IsolationManager.shared.setStillHavingFever(isAnswerYes) }))
        
        return rows
    }

}

// MARK: - Prebuilt contact case rows -
extension IsolationFormViewController {

    private func lastContactDateRow() -> CVRow {
        let row: CVRow = dateRow(title: "isolationFormController.contactCase.lastContactDate".localized,
                                 date: IsolationManager.shared.isolationLastContactDate) { newDate, closePicker in
            IsolationManager.shared.updateLastContactDate(newDate, notifyChange: closePicker)
        }
        return row
    }

    private func indexSymptomsEndDateRow() -> CVRow {
        let row: CVRow = dateRow(title: "isolationFormController.contactCase.symptomsEndDate".localized,
                                 date: IsolationManager.shared.isolationIndexSymptomsEndDate) { newDate, closePicker in
            IsolationManager.shared.updateIndexSymptomsEndDate(newDate, notifyChange: closePicker)
        }
        return row
    }
    
    private func yesNoQuestionRows(title: String, isAnswerYes: Bool?, answerBlock: @escaping (_ isAnswerYes: Bool) -> ()) -> [CVRow] {
        var rows: [CVRow] = []
        rows.append(sectionRow(title: title))
        rows.append(selectableRow(title: "common.yes".localized,
                                  isSelected: isAnswerYes == true,
                                  isLastRowInGroup: false,
                                  selectionBlock: { answerBlock(true) }))
        rows.append(selectableRow(title: "common.no".localized,
                                  isSelected: isAnswerYes == false,
                                  isLastRowInGroup: true,
                                  selectionBlock: { answerBlock(false) }))
        return rows
    }

    private func readRecommendationsRow() -> CVRow {
        let row: CVRow = CVRow(title: "isolationFormController.readRecommendations".localized,
                               xibName: .buttonCell,
                               theme: CVRow.Theme(topInset: 20.0,
                                                  bottomInset: 0.0,
                                                  buttonStyle: .secondary),
                               selectionAction: { [weak self] in
                                    self?.didTouchCloseButton()
                               })
        return row
    }

}

// MARK: - Prebuilt positive case rows -
extension IsolationFormViewController {

    private func positiveTestDateRow() -> CVRow {
        let row: CVRow = dateRow(title: "isolationFormController.positiveCase.positiveTestDate".localized,
                                 date: IsolationManager.shared.isolationPositiveTestingDate) { newDate, closePicker in
            IsolationManager.shared.updatePositiveTestingDate(newDate, notifyChange: closePicker)
        }
        return row
    }
    
    private func symptomsStartDateRow() -> CVRow {
        let row: CVRow = dateRow(title: "isolationFormController.positiveCase.symptomsStartDate".localized,
                                 date: IsolationManager.shared.isolationSymptomsStartDate) { newDate, closePicker in
            IsolationManager.shared.updateSymptomsStartDate(newDate, notifyChange: closePicker)
        }
        return row
    }

}

// MARK: - Raw components rows -
extension IsolationFormViewController {
    
    private func selectableRow(title: String, isSelected: Bool, isLastRowInGroup: Bool, selectionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               xibName: .textCell,
                               theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                  topInset: Appearance.Cell.leftMargin,
                                                  bottomInset: Appearance.Cell.leftMargin,
                                                  textAlignment: .natural,
                                                  titleFont: { Appearance.Cell.Text.standardFont },
                                                  separatorLeftInset: isLastRowInGroup ? 0.0 : Appearance.Cell.leftMargin,
                                                  separatorRightInset: 0.0),
                               selectionAction: {
                                selectionBlock()
                               }, willDisplay: { cell in
                                cell.accessoryType = isSelected ? .checkmark : .none
                               })
        return row
    }
    
    private func dateRow(title: String, date: Date?, dateChangedBlock: @escaping (_ newDate: Date, _ closePicker: Bool) -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               subtitle: date?.dayMonthYearFormatted(),
                               placeholder: "-",
                               xibName: .dateCell,
                               theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                  topInset: 10.0,
                                                  bottomInset: 10.0,
                                                  textAlignment: .natural,
                                                  titleFont: { .regular(size: 12.0) },
                                                  titleColor: Appearance.Cell.Text.subtitleColor,
                                                  subtitleFont: { .regular(size: 17.0) },
                                                  subtitleColor: Appearance.Cell.Text.titleColor,
                                                  separatorLeftInset: 0.0,
                                                  separatorRightInset: 0.0),
                               minimumDate: Date().dateByAddingDays(-30),
                               maximumDate: Date(),
                               initialDate: date,
                               datePickerMode: .date,
                               valueChanged: { value in
                                    guard let value = value as? Date else { return }
                                    dateChangedBlock(value, false)
                               }, didValidateValue: { value, _ in
                                    guard let value = value as? Date else { return }
                                    dateChangedBlock(value, true)
                               }, displayValueForValue: { value -> String? in
                                    guard let value = value as? Date else { return nil }
                                    return value.dayMonthYearFormatted()
                               })
        return row
    }
    
    private func sectionRow(title: String) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               xibName: .textCell,
                               theme: CVRow.Theme(topInset: Appearance.Cell.leftMargin,
                                                  bottomInset: Appearance.Cell.leftMargin,
                                                  textAlignment: .natural,
                                                  titleColor: Appearance.tintColor,
                                                  separatorLeftInset: 0.0,
                                                  separatorRightInset: 0.0))
        return row
    }
    
}

extension IsolationFormViewController: IsolationChangesObserver {
    
    func isolationDidUpdate() {
        reloadUI(animated: true)
    }
    
}
