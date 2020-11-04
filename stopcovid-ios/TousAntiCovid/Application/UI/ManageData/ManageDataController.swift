// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ManageDataController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/05/2020 - for the TousAntiCovid project.
//


import UIKit
import PKHUD
import RobertSDK
import ServerSDK

final class ManageDataController: CVTableViewController {
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must use the standard init() method.")
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
    
    func updateTitle() {
        title = "manageDataController.title".localized
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let showInfoNotificationsRows: [CVRow] = switchRowsBlock(textPrefix: "manageDataController.showInfoNotifications",
                                                                 isOn: NotificationsManager.shared.showNewInfoNotification) { isOn in
            NotificationsManager.shared.showNewInfoNotification = isOn
        }
        rows.append(contentsOf: showInfoNotificationsRows)
        let attestationRows: [CVRow] = rowsBlock(textPrefix: "manageDataController.attestationsData") { [weak self] in
            self?.eraseAttestationDataButtonPressed()
        }
        rows.append(contentsOf: attestationRows)
        let historyRows: [CVRow] = rowsBlock(textPrefix: "manageDataController.eraseLocalHistory") { [weak self] in
            self?.eraseLocalHistoryButtonPressed()
        }
        rows.append(contentsOf: historyRows)
        let contactRows: [CVRow] = rowsBlock(textPrefix: "manageDataController.eraseRemoteContact") { [weak self] in
            self?.eraseContactsButtonPressed()
        }
        rows.append(contentsOf: contactRows)
        let alertRows: [CVRow] = rowsBlock(textPrefix: "manageDataController.eraseRemoteAlert") { [weak self] in
            self?.eraseAlertsButtonPressed()
        }
        rows.append(contentsOf: alertRows)
        let quitRows: [CVRow] = rowsBlock(textPrefix: "manageDataController.quitStopCovid", isDestuctive: true) { [weak self] in
            self?.quitButtonPressed()
        }
        rows.append(contentsOf: quitRows)
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
    
    private func switchRowsBlock(textPrefix: String, isOn: Bool, handler: @escaping (_ isOn: Bool) -> ()) -> [CVRow] {
        let textRow: CVRow = CVRow(title: "\(textPrefix).title".localized,
                                   subtitle: "\(textPrefix).subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 2 * Appearance.Cell.leftMargin,
                                                      bottomInset: Appearance.Cell.leftMargin,
                                                      textAlignment: .natural,
                                                      separatorLeftInset: Appearance.Cell.leftMargin))
        let switchRow: CVRow = CVRow(title: "\(textPrefix).button".localized,
                                      isOn: isOn,
                                      xibName: .standardSwitchCell,
                                      theme: CVRow.Theme(topInset: 10.0,
                                                         bottomInset: 10.0,
                                                         textAlignment: .left,
                                                         titleFont: { Appearance.Cell.Text.standardFont },
                                                         separatorLeftInset: 0.0,
                                                         separatorRightInset: 0.0),
                                      valueChanged: { value in
            guard let isOn = value as? Bool else { return }
            handler(isOn)
        })
        return [textRow, switchRow]
    }
    
    private func rowsBlock(textPrefix: String, isDestuctive: Bool = false, handler: @escaping () -> ()) -> [CVRow] {
        let textRow: CVRow = CVRow(title: "\(textPrefix).title".localized,
                                   subtitle: "\(textPrefix).subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 2 * Appearance.Cell.leftMargin,
                                                      bottomInset: Appearance.Cell.leftMargin,
                                                      textAlignment: .natural,
                                                      separatorLeftInset: Appearance.Cell.leftMargin))
        let buttonRow: CVRow = CVRow(title: "\(textPrefix).button".localized,
                                     xibName: .standardCell,
                                     theme: CVRow.Theme(topInset: 15.0,
                                                        bottomInset: 15.0,
                                                        textAlignment: .natural,
                                                        titleFont: { Appearance.Cell.Text.standardFont },
                                                        titleColor: isDestuctive ? Asset.Colors.error.color : Asset.Colors.tint.color,
                                                        separatorLeftInset: 0.0,
                                                        separatorRightInset: 0.0),
                                     selectionAction: { handler() },
                                     willDisplay: { cell in
                cell.accessoryType = .none
                cell.cvTitleLabel?.accessibilityTraits = .button
        })
        return [textRow, buttonRow]
    }
    
    @objc private func didTouchBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func eraseAttestationDataButtonPressed() {
        showAlert(title: "manageDataController.attestationsData.confirmationDialog.title".localized,
                  message: "manageDataController.attestationsData.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
                    AttestationsManager.shared.clearAllData()
                    self?.showFlash()
                  })
    }
    
    private func eraseLocalHistoryButtonPressed() {
        showAlert(title: "manageDataController.eraseLocalHistory.confirmationDialog.title".localized,
                  message: "manageDataController.eraseLocalHistory.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
                    RBManager.shared.clearLocalProximityList()
                    self?.showFlash()
                  })
    }
    
    private func eraseContactsButtonPressed() {
        showAlert(title: "manageDataController.eraseRemoteContact.confirmationDialog.title".localized,
                  message: "manageDataController.eraseRemoteContact.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
                    if RBManager.shared.isRegistered {
                        HUD.show(.progress)
                        RBManager.shared.deleteExposureHistory { error in
                            HUD.hide()
                            if let error = error {
                                if (error as NSError).code == -1 {
                                    self?.showAlert(title: "common.error.clockNotAligned.title".localized,
                                                    message: "common.error.clockNotAligned.message".localized,
                                                    okTitle: "common.ok".localized)
                                } else {
                                    self?.showAlert(title: "common.error".localized,
                                                    message: "common.error.server".localized,
                                                    okTitle: "common.ok".localized)
                                }
                            } else {
                                self?.showFlash()
                            }
                        }
                    } else {
                        self?.showFlash()
                    }
                  })
    }
    
    private func eraseAlertsButtonPressed() {
        showAlert(title: "manageDataController.eraseRemoteAlert.confirmationDialog.title".localized,
                  message: "manageDataController.eraseRemoteAlert.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  { [weak self] in
                    RBManager.shared.clearAtRiskAlert()
                    self?.showFlash()
                  })
    }
    
    private func quitButtonPressed() {
        showAlert(title: "manageDataController.quitStopCovid.confirmationDialog.title".localized,
                  message: "manageDataController.quitStopCovid.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  {
                    switch ParametersManager.shared.apiVersion {
                    case .v3:
                        HUD.show(.progress)
                        RBManager.shared.unregisterV3 { [weak self] error, isErrorBlocking in
                            HUD.hide()
                            self?.processPostUnregisterActions(error, isErrorBlocking: isErrorBlocking)
                        }
                    default:
                        HUD.show(.progress)
                        RBManager.shared.unregister { [weak self] error, isErrorBlocking in
                            HUD.hide()
                            self?.processPostUnregisterActions(error, isErrorBlocking: isErrorBlocking)
                        }
                    }
                  })
    }
    
    private func processPostUnregisterActions(_ error: Error?, isErrorBlocking: Bool) {
        if let error = error, (error as NSError).code == -1 {
            showAlert(title: "common.error.clockNotAligned.title".localized,
                      message: "common.error.clockNotAligned.message".localized,
                      okTitle: "common.ok".localized)
        } else if error != nil && isErrorBlocking {
            showAlert(title: "common.error".localized,
                      message: "common.error.server".localized,
                      okTitle: "common.ok".localized)
        } else {
            ParametersManager.shared.clearConfig()
            NotificationCenter.default.post(name: .changeAppState, object: RootCoordinator.State.onboarding, userInfo: nil)
        }
    }
    
}

extension ManageDataController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
