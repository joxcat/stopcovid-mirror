// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/01/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class VaccinationController: CVTableViewController {
    
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
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = "vaccinationController.title".localized
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let eligibilityRow: CVRow = CVRow(title: "vaccinationController.eligibility.title".localized,
                                          subtitle: "vaccinationController.eligibility.subtitle".localized,
                                          buttonTitle: "vaccinationController.eligibility.buttonTitle".localized,
                                          xibName: .paragraphCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 20.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .left,
                                                             titleFont: { Appearance.Cell.Text.headTitleFont }),
                                          selectionAction: {
                                            URL(string: "vaccinationController.eligibility.url".localized)?.openInSafari()
                                          })
        rows.append(eligibilityRow)
        let locationRow: CVRow = CVRow(title: "vaccinationController.vaccinationLocation.title".localized,
                                       subtitle: "vaccinationController.vaccinationLocation.subtitle".localized,
                                       buttonTitle: "vaccinationController.vaccinationLocation.buttonTitle".localized,
                                       xibName: .paragraphCell,
                                       theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                          topInset: 10.0,
                                                          bottomInset: 10.0,
                                                          textAlignment: .left,
                                                          titleFont: { Appearance.Cell.Text.headTitleFont }),
                                       selectionAction: {
                                        URL(string: "vaccinationController.vaccinationLocation.url".localized)?.openInSafari()
                                       })
        rows.append(locationRow)
        return rows
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
    }

}

extension VaccinationController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
