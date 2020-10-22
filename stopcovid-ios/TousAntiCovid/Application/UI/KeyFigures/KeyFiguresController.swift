// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/09/2020 - for the TousAntiCovid project.
//

import UIKit

final class KeyFiguresController: CVTableViewController {
    
    private let deinitBlock: () -> ()
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "keyFiguresController.title".localized
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 10.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        KeyFiguresManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        KeyFiguresManager.shared.removeObserver(self)
    }
    
    override func reloadUI(animated: Bool = false, completion: (() -> ())? = nil) {
        super.reloadUI(animated: animated, completion: completion)
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let healthSectionRow: CVRow =  CVRow(title: "keyFiguresController.section.health".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 12.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Cell.Text.valueFont }))
        rows.append(healthSectionRow)
        let keyFiguresHealthRows: [CVRow] = KeyFiguresManager.shared.keyFigures.filter { $0.category == .health }.map { keyFigure in
            CVRow(title: keyFigure.label,
                  subtitle: keyFigure.description,
                  accessoryText: keyFigure.formattedDate,
                  xibName: .keyFigureCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: 10.0,
                                     bottomInset: 10.0,
                                     textAlignment: .natural,
                                     titleFont: { Appearance.Cell.Text.titleFont }),
                  associatedValue: keyFigure)
        }
        rows.append(contentsOf: keyFiguresHealthRows)
        let appSectionRow: CVRow =  CVRow(title: "keyFiguresController.section.app".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 12.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.valueFont }))
        rows.append(appSectionRow)
        let keyFiguresAppRows: [CVRow] = KeyFiguresManager.shared.keyFigures.filter { $0.category == .app }.map { keyFigure in
            CVRow(title: keyFigure.label,
                  subtitle: keyFigure.description,
                  accessoryText: keyFigure.formattedDate,
                  xibName: .keyFigureCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: 10.0,
                                     bottomInset: 10.0,
                                     textAlignment: .natural,
                                     titleFont: { Appearance.Cell.Text.titleFont }),
                  associatedValue: keyFigure)
        }
        rows.append(contentsOf: keyFiguresAppRows)
        return rows
    }

}

extension KeyFiguresController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        reloadUI()
    }

}
