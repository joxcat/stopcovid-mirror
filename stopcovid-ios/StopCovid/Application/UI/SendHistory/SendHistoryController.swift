// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SendHistoryController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the STOP-COVID project.
//


import UIKit
import PKHUD
import RobertSDK
import ServerSDK

final class SendHistoryController: CVTableViewController {
    
    let symptomsParams: SymptomsDeclarationParams
    let dismissBlock: () -> ()
    
    init(symptomsParams: SymptomsDeclarationParams, dismissBlock: @escaping () -> ()) {
        self.symptomsParams = symptomsParams
        self.dismissBlock = dismissBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomButtonContainerController?.title = "sendHistoryController.title".localized
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    override func createRows() -> [CVRow] {
        let imageRow: CVRow = CVRow(image: Asset.Images.envoiData.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: 40.0,
                                                       imageRatio: Appearance.Cell.Image.defaultRatio))
        let textRow: CVRow = CVRow(title: "sendHistoryController.mainMessage.title".localized,
                                   subtitle: "sendHistoryController.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 20.0))
        return [imageRow, textRow]
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        bottomButtonContainerController?.updateButton(title: "common.send".localized) { [weak self] in
            self?.sendButtonPressed()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func sendButtonPressed() {
        HUD.show(.progress)
        RBManager.shared.report(code: symptomsParams.code, symptomsOrigin: symptomsParams.date) { error in
            HUD.hide()
            if let error = error {
                if (error as NSError).code == -1 {
                    self.showAlert(title: "common.error.clockNotAligned.title".localized,
                                    message: "common.error.clockNotAligned.message".localized,
                                    okTitle: "common.ok".localized)
                } else {
                    self.showAlert(title: "sendHistoryController.alert.invalidCode.title".localized,
                                   message: "sendHistoryController.alert.invalidCode.message".localized,
                                   okTitle: "common.ok".localized,
                                   handler: {
                        self.dismissBlock()
                    })
                }
                self.bottomButtonContainerController?.unlockButtons()
            } else {
                switch ParametersManager.shared.apiVersion {
                case .v3:
                    RBManager.shared.unregisterV3 { error, _ in
                        ParametersManager.shared.clearConfig()
                        RBManager.shared.isSick = true
                        self.dismissBlock()
                    }
                default:
                    RBManager.shared.unregister { error, _ in
                        ParametersManager.shared.clearConfig()
                        RBManager.shared.isSick = true
                        self.dismissBlock()
                    }
                }
            }
        }
    }
    
}

extension SendHistoryController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        reloadUI()
    }
    
}
