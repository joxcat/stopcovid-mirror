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
    
    private let didTouchKeyFigure: (_ keyFigure: KeyFigure) -> ()
    private let didTouchReadExplanationsNow: () -> ()
    private let deinitBlock: () -> ()
    
    init(didTouchReadExplanationsNow: @escaping () -> (),
         didTouchKeyFigure: @escaping(_ keyFigure: KeyFigure) -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchReadExplanationsNow = didTouchReadExplanationsNow
        self.didTouchKeyFigure = didTouchKeyFigure
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
        deinitBlock()
    }
    
    private func initUI() {
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 10.0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        updateRightBarButtonItem()
    }
    
    private func updateRightBarButtonItem() {
        if KeyFiguresManager.shared.displayDepartmentLevel {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.location.image, style: .plain, target: self, action: #selector(didTouchLocationButton))
            navigationItem.rightBarButtonItem?.accessibilityLabel = "accessibility.hint.postalCode.button".localized
        } else {
            navigationItem.rightBarButtonItem = nil
        }
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
                                             subtitle: "keyFiguresController.section.health.subtitle".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 12.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Cell.Text.headTitleFont }))
        rows.append(healthSectionRow)
        let readNowRow: CVRow = CVRow(buttonTitle: "keyFiguresController.section.health.button".localized,
                                             xibName: .linkButtonCell,
                                             theme:  CVRow.Theme(topInset: 0.0,
                                                                 bottomInset: 20.0),
                                             secondarySelectionAction: { [weak self] in
                                                self?.didTouchReadExplanationsNow()
                                             })
        rows.append(readNowRow)
        let keyFiguresHealthRows: [CVRow] = KeyFiguresManager.shared.keyFigures.filter { $0.category == .health }.map { keyFigure in
            CVRow(title: keyFigure.label,
                  subtitle: keyFigure.description,
                  xibName: .keyFigureCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: 10.0,
                                     bottomInset: 10.0,
                                     textAlignment: .natural,
                                     subtitleLinesCount: 2),
                  associatedValue: keyFigure,
                  selectionActionWithCell: { [weak self] cell in
                    self?.didTouchSharingFor(cell: cell, keyFigure: keyFigure)
                  },
                  selectionAction: { [weak self] in
                    self?.didTouchKeyFigure(keyFigure)
                  },
                  willDisplay: { cell in
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                  })
        }
        rows.append(contentsOf: keyFiguresHealthRows)
        let appSectionRow: CVRow =  CVRow(title: "keyFiguresController.section.app".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 12.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.headTitleFont }))
        rows.append(appSectionRow)
        let keyFiguresAppRows: [CVRow] = KeyFiguresManager.shared.keyFigures.filter { $0.category == .app }.map { keyFigure in
            CVRow(title: keyFigure.label,
                  subtitle: keyFigure.description,
                  xibName: .keyFigureCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: 10.0,
                                     bottomInset: 10.0,
                                     textAlignment: .natural,
                                     subtitleLinesCount: 2),
                  associatedValue: keyFigure,
                  selectionActionWithCell: { [weak self] cell in
                    self?.didTouchSharingFor(cell: cell, keyFigure: keyFigure)
                  },
                  selectionAction: { [weak self] in
                    self?.didTouchKeyFigure(keyFigure)
                  },
                  willDisplay: { cell in
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                  })
        }
        rows.append(contentsOf: keyFiguresAppRows)
        return rows
    }
    
    @objc private func didTouchLocationButton() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }
    
    private func didTouchSharingFor(cell: CVTableViewCell, keyFigure: KeyFigure) {
        let sharingText: String
        if let keyFigureDepartment = keyFigure.currentDepartmentSpecificKeyFigure {
            sharingText = String(format: "keyFigure.sharing.department".localized,
                                 keyFigure.label,
                                 keyFigureDepartment.label,
                                 keyFigureDepartment.valueToDisplay,
                                 keyFigure.label,
                                 keyFigure.valueGlobalToDisplay)
        } else {
            sharingText = String(format: "keyFigure.sharing.national".localized,
                                 keyFigure.label,
                                 keyFigure.valueGlobalToDisplay)
        }
        let activityItems: [Any?] = [sharingText, KeyFigureCaptureView.captureKeyFigure(keyFigure)]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

}

extension KeyFiguresController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        reloadNextToKeyFiguresUpdate()
    }
    
    func postalCodeDidUpdate(_ postalCode: String?) {
        reloadNextToKeyFiguresUpdate()
    }
    
    private func reloadNextToKeyFiguresUpdate() {
        updateRightBarButtonItem()
        reloadUI(animated: true)
    }

}
