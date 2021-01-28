// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresExplanationsController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/09/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class KeyFiguresExplanationsController: CVTableViewController {
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = "keyFiguresExplanationsController.title".localized
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = [blockSeparatorRow()]
        let sections: [KeyFiguresExplanationsSection] = KeyFiguresExplanationsManager.shared.keyFiguresExplanationsSection
        let sectionsRows: [CVRow] = sections.map { section in
            let sectionRow: CVRow = CVRow(title: section.section,
                                          subtitle: section.description,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: Appearance.Cell.leftMargin,
                                                             bottomInset: Appearance.Cell.leftMargin,
                                                             textAlignment: .natural,
                                                             separatorLeftInset: Appearance.Cell.leftMargin))
            let linkRows: [CVRow] = section.links?.map { link in
                CVRow(title: link.label,
                      xibName: .standardCell,
                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                         topInset: Appearance.Cell.leftMargin,
                                         bottomInset: Appearance.Cell.leftMargin,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.Cell.Text.standardFont },
                                         titleColor: Appearance.tintColor,
                                         separatorLeftInset: 0.0),
                      selectionAction: {
                        URL(string: link.url)?.openInSafari()
                      }, willDisplay: { cell in
                        cell.cvTitleLabel?.accessibilityTraits = .button
                        cell.accessoryType = .none
                })
            } ?? []
            return [sectionRow] + linkRows + [blockSeparatorRow()]
        }.reduce([], +)
        rows.append(contentsOf: sectionsRows)
        rows.removeLast()
        rows.append(.empty)
        return rows
    }
    
    private func blockSeparatorRow() -> CVRow {
        var row: CVRow = .emptyFor(topInset: 15.0, bottomInset: 15.0)
        row.theme.separatorLeftInset = 0.0
        row.theme.separatorRightInset = 0.0
        return row
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
        LinksManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        LinksManager.shared.removeObserver(self)
    }

}

extension KeyFiguresExplanationsController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension KeyFiguresExplanationsController: LinksChangesObserver {
    
    func linksChanged() {
        reloadUI()
    }
    
}
