// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InformationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK

final class InformationController: CVTableViewController {
    
    private var showGesturesBlock: (() -> ())?
    
    init(showGesturesBlock: (() -> ())?) {
        self.showGesturesBlock = showGesturesBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    override func createRows() -> [CVRow] {
        let isAtRisk: Bool = RBManager.shared.isAtRisk
        var rows: [CVRow] = []
        let textVariantToken: String = isAtRisk ? "atRisk" : "nothing"
        let textRow: CVRow = CVRow(title: "informationController.mainMessage.\(textVariantToken).title".localized,
                                   subtitle: "informationController.mainMessage.\(textVariantToken).subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 30.0, bottomInset: 20.0, separatorLeftInset: nil))
        rows.append(textRow)
        
        let step1Rows: [CVRow] = rowsBlock(title: String(format: "informationController.step.isolate.\(textVariantToken).title".localized, 1),
                                           subtitle: "informationController.step.isolate.\(textVariantToken).subtitle".localized,
                                           buttonTitle: "informationController.step.isolate.buttonTitle".localized) { [weak self] in
            self?.showGesturesBlock?()
        }
        rows.append(contentsOf: step1Rows)
        
        let step2Rows: [CVRow] = rowsBlock(title: String(format: "informationController.step.beCareful.\(textVariantToken).title".localized, 2),
                                           subtitle: "informationController.step.beCareful.\(textVariantToken).subtitle".localized,
                                           buttonTitle: "informationController.step.beCareful.buttonTitle".localized) {
            URL(string: "sickController.button.myConditionInformation.url".localized)?.openInSafari()
        }
        rows.append(contentsOf: step2Rows)
        
        let step3VariantToken: String = isAtRisk ? "appointment" : "moreInfo"
        let step3Rows: [CVRow] = rowsBlock(title: String(format: "informationController.step.\(step3VariantToken).title".localized, 3),
                                           subtitle: "informationController.step.\(step3VariantToken).subtitle".localized,
                                           buttonTitle: "informationController.step.\(step3VariantToken).buttonTitle".localized) { [weak self] in
            guard let self = self else { return }
            if isAtRisk {
                "callCenter.phoneNumber".localized.callPhoneNumber(from: self)
            } else {
                URL(string: "informationController.step.moreInfo.url".localized)?.openInSafari()
            }
        }
        rows.append(contentsOf: step3Rows)
        
        if isAtRisk {
            let step4Rows: [CVRow] = rowsBlock(title: String(format: "informationController.step.moreInfo.title".localized, 4),
                                               subtitle: "informationController.step.moreInfo.subtitle".localized,
                                               buttonTitle: "informationController.step.moreInfo.buttonTitle".localized) {
                URL(string: "informationController.step.moreInfo.url".localized)?.openInSafari()
            }
            rows.append(contentsOf: step4Rows)
        }
        
        return rows
    }
    
    func updateTitle() {
        title = "informationController.title".localized
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func rowsBlock(title: String, subtitle: String, buttonTitle: String, buttonAction: @escaping () -> ()) -> [CVRow] {
        let textRow: CVRow = CVRow(title: title,
                                   subtitle: subtitle,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 30.0, bottomInset: 0.0, textAlignment: .center, separatorLeftInset: nil))
        let buttonRow: CVRow = CVRow(title: buttonTitle,
                                     xibName: .buttonCell,
                                     theme: CVRow.Theme(topInset: 15.0, separatorLeftInset: nil, buttonStyle: .secondary),
                                     selectionAction: { buttonAction() })
        return [textRow, buttonRow]
    }

}

extension InformationController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

