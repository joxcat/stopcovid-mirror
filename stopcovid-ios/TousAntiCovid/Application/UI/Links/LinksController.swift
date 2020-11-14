// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LinksController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/09/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class LinksController: CVTableViewController {
    
    private let deinitBlock: () -> ()
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
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
        deinitBlock()
    }
    
    private func updateTitle() {
        title = "linksController.title".localized
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let sections: [LinksSection] = LinksManager.shared.linksSections
        let sectionsRows: [CVRow] = sections.map { section in
            let sectionRow: CVRow = CVRow(title: section.section,
                                          subtitle: section.description,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 15.0,
                                                             textAlignment: .natural,
                                                             separatorLeftInset: Appearance.Cell.leftMargin))
            let linkRows: [CVRow] = section.links?.map { link in
                CVRow(title: link.label,
                      xibName: .standardCell,
                      theme: CVRow.Theme(topInset: 15.0,
                                         bottomInset: 15.0,
                                         textAlignment: .natural,
                                         titleFont: { Appearance.Cell.Text.standardFont },
                                         titleColor: Appearance.tintColor,
                                         separatorLeftInset: Appearance.Cell.leftMargin),
                      selectionAction: {
                        URL(string: link.url)?.openInSafari()
                      }, willDisplay: { cell in
                        cell.cvTitleLabel?.accessibilityTraits = .button
                        cell.accessoryType = .none
                })
            } ?? []
            return [sectionRow] + linkRows
        }.reduce([], +)
        rows.append(contentsOf: sectionsRows)
        rows.append(.empty)
        return rows
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
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

extension LinksController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension LinksController: LinksChangesObserver {
    
    func linksChanged() {
        reloadUI()
    }
    
}
