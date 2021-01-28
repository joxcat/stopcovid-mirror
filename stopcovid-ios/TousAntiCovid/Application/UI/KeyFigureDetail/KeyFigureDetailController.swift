// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureDetailController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class KeyFigureDetailController: CVTableViewController {
    
    private let keyFigure: KeyFigure
    private let deinitBlock: () -> ()
    
    init(keyFigure: KeyFigure, deinitBlock: @escaping () -> ()) {
        self.keyFigure = keyFigure
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = keyFigure.shortLabel
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
        rows.append(createKeyFigureRow())
        rows.append(contentsOf: createChartRows())
        guard !keyFigure.learnMore.isEmpty else { return rows }
        let learnMoreSectionRow: CVRow =  CVRow(title: "keyFigureDetailController.section.learnmore.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 12.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.valueFont }))
        rows.append(learnMoreSectionRow)
        let learnMoreRow: CVRow = CVRow(subtitle: keyFigure.learnMore,
                                        xibName: .standardCardCell,
                                        theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                            topInset: 0.0,
                                                            bottomInset: 20.0,
                                                            textAlignment: .natural))
        rows.append(learnMoreRow)
        return rows
    }
    
    private func createKeyFigureRow() -> CVRow {
        CVRow(title: keyFigure.label,
              subtitle: keyFigure.description,
              xibName: .keyFigureCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: 10.0,
                                 bottomInset: 0.0,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.titleFont }),
              associatedValue: keyFigure,
              selectionActionWithCell: { [weak self] cell in
                self?.didTouchSharingFor(cell: cell)
              })
    }
    
    private func createChartRows() -> [CVRow] {
        var rows: [CVRow] = []
        let chartSectionRow: CVRow =  CVRow(title: "keyFigureDetailController.section.evolution.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 12.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.valueFont }))
        rows.append(chartSectionRow)
        
        let chartDatas: [KeyFigureChartData] = KeyFiguresManager.shared.generateChartData(from: keyFigure)
        if keyFigure.displayOnSameChart {
            let chartsRow: CVRow = CVRow(xibName: .keyFigureChartCell,
                                        theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                            topInset: 0.0,
                                                            bottomInset: 20.0,
                                                            textAlignment: .natural),
                                        associatedValue: chartDatas,
                                        selectionActionWithCell: { [weak self] cell in
                                          self?.didTouchSharingFor(cell: cell)
                                        })
            rows.append(chartsRow)
        } else {
            let chartRows: [CVRow] = chartDatas.map {
                CVRow(xibName: .keyFigureChartCell,
                      theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                          topInset: 0.0,
                                          bottomInset: 20.0,
                                          textAlignment: .natural),
                      associatedValue: [$0],
                      selectionActionWithCell: { [weak self] cell in
                        self?.didTouchSharingFor(cell: cell)
                      })
            }
            rows.append(contentsOf: chartRows)
        }
        
        return rows
    }
    
    @objc private func didTouchLocationButton() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }
    
    private func didTouchSharingFor(cell: CVTableViewCell) {
        var activityItems: [Any?] = []
        if cell is KeyFigureCell {
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
            activityItems.append(sharingText)
            activityItems.append(KeyFigureCaptureView.captureKeyFigure(keyFigure))
        } else {
            activityItems.append(cell.capture())
        }
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

}

extension KeyFigureDetailController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        updateRightBarButtonItem()
        reloadUI(animated: true)
    }

}
