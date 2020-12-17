// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class SickController: CVTableViewController {
    
    private let didTouchAbout: () -> ()
    private let didTouchReadMore: () -> ()
    private let didTouchCautionMeasures: () -> ()
    
    init(didTouchAbout: @escaping () -> (), didTouchReadMore: @escaping () -> (), didTouchCautionMeasures: @escaping () -> ()) {
        self.didTouchAbout = didTouchAbout
        self.didTouchReadMore = didTouchReadMore
        self.didTouchCautionMeasures = didTouchCautionMeasures
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
        if !RBManager.shared.isSick {
            addObservers()
        }
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = RBManager.shared.isSick ? "myHealthController.sick.title".localized : "myHealthController.title".localized
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = baseRows()
        if RBManager.shared.isSick {
            return sickRows()
        } else if !RBManager.shared.isRegistered {
            rows.append(contentsOf: notRegisteredRows())
        } else {
            if RBManager.shared.lastStatusReceivedDate != nil {
                rows.append(RBManager.shared.isAtRisk ? contactRow() : (VenuesManager.shared.lastWarningRiskReceivedDate != nil ? warningRow() : nothingRow()))
            }
            rows.append(contentsOf: paragraphsRows(showNotificationInfoRow: !RBManager.shared.isAtRisk))
        }
        return rows
    }
    
    private func contactRow() -> CVRow {
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String = notificationDate?.relativelyFormatted() ?? "N/A"
        
        let colors: (startColor: UIColor, endColor: UIColor, buttonColor: UIColor) = (Asset.Colors.gradientStartRed.color,
                                                                                      Asset.Colors.gradientEndRed.color,
                                                                                      Asset.Colors.notificationRiskButtonBackground.color)
        
        let stateRow: CVRow = CVRow(title: "sickController.state.contact.title".localized,
                                    subtitle: "sickController.state.contact.subtitle".localized,
                                    accessoryText: notificationDateString,
                                    buttonTitle: "myHealthController.alert.atitudeToAdopt".localized,
                                    xibName: .sickStateHeaderCell,
                                    theme: CVRow.Theme(topInset: 0.0,
                                                       bottomInset: 10.0,
                                                       textAlignment: .natural,
                                                       accessoryTextFont: { Appearance.Cell.Text.accessoryFont }),
                                    associatedValue: colors,
                                    secondarySelectionAction: { [weak self] in
            self?.didTouchMoreButton()
        }, tertiarySelectionAction: { [weak self] in
            self?.didTouchReadMoreButton()
        })
        return stateRow
    }
    
    private func warningRow() -> CVRow {
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String = notificationDate?.relativelyFormatted() ?? "N/A"
        
        let colors: (startColor: UIColor, endColor: UIColor, buttonColor: UIColor) = (Asset.Colors.gradientStartOrange.color,
                                                                                      Asset.Colors.gradientEndOrange.color,
                                                                                      Asset.Colors.notificationWarningButtonBackground.color)
        
        let stateRow: CVRow = CVRow(title: "sickController.state.warning.title".localized,
                                    subtitle: "sickController.state.warning.subtitle".localized,
                                    accessoryText: notificationDateString,
                                    buttonTitle: "myHealthController.alert.atitudeToAdopt".localized,
                                    xibName: .sickStateHeaderCell,
                                    theme: CVRow.Theme(topInset: 0.0,
                                                       bottomInset: 10.0,
                                                       textAlignment: .natural,
                                                       accessoryTextFont: { Appearance.Cell.Text.accessoryFont }),
                                    associatedValue: colors,
                                    secondarySelectionAction: { [weak self] in
            self?.didTouchMoreButton()
        }, tertiarySelectionAction: { [weak self] in
            self?.didTouchReadMoreButton()
        })
        return stateRow
    }
    
    private func nothingRow() -> CVRow {
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String = notificationDate?.relativelyFormatted() ?? "N/A"
        
        let colors: (startColor: UIColor, endColor: UIColor, buttonColor: UIColor) = (Asset.Colors.gradientStartGreen.color,
                                                                                      Asset.Colors.gradientEndGreen.color,
                                                                                      Asset.Colors.notificationButtonBackground.color)
        
        let stateRow: CVRow = CVRow(title: "sickController.state.nothing.title".localized,
                                    subtitle: "sickController.state.nothing.subtitle".localized,
                                    accessoryText: notificationDateString,
                                    buttonTitle: "myHealthController.alert.atitudeToAdopt".localized,
                                    xibName: .sickStateHeaderCell,
                                    theme: CVRow.Theme(topInset: 0.0,
                                                       bottomInset: 10.0,
                                                       textAlignment: .natural,
                                                       accessoryTextFont: { Appearance.Cell.Text.accessoryFont }),
                                    associatedValue: colors,
                                    secondarySelectionAction: { [weak self] in
            self?.didTouchMoreButton()
        }, tertiarySelectionAction: { [weak self] in
            self?.didTouchReadMoreButton()
        })
        return stateRow
    }
    
    private func sickRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.sick.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: 20.0))
        rows.append(imageRow)
        let declarationTextRow: CVRow = CVRow(title: "sickController.sick.mainMessage.title".localized,
                                              subtitle: "sickController.sick.mainMessage.subtitle".localized,
                                              xibName: .textCell,
                                              theme: CVRow.Theme(topInset: 40.0, bottomInset: 40.0))
        rows.append(declarationTextRow)
        let recommendationsButton: CVRow = CVRow(title: "sickController.button.recommendations".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0, buttonStyle: .primary),
                                        selectionAction: {
            URL(string: "sickController.button.recommendations.url".localized)?.openInSafari()
        })
        rows.append(recommendationsButton)
        let phoneButton: CVRow = CVRow(title: "informationController.step.appointment.buttonTitle".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0, buttonStyle: .primary),
                                            selectionAction: { [weak self] in
            guard let self = self else { return }
            "callCenter.phoneNumber".localized.callPhoneNumber(from: self)
        })
        rows.append(phoneButton)
        let measuresButton: CVRow = CVRow(title: "sickController.button.cautionMeasures".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0, buttonStyle: .primary),
                                            selectionAction: { [weak self] in
                                                self?.didTouchCautionMeasures()
        })
        rows.append(measuresButton)
        return rows
    }
    
    private func baseRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.diagnosis.image,
                                    xibName: .imageCell,
                                    theme: CVRow.Theme(topInset: 20.0,
                                                       imageRatio: 375.0 / 233.0))
        rows.append(imageRow)
        return rows
    }
    
    private func notRegisteredRows() -> [CVRow] {
        let textRow: CVRow = CVRow(title: "myHealthController.notRegistered.mainMessage.title".localized,
                                   subtitle: "myHealthController.notRegistered.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 20.0))
        return [textRow]
    }
    
    private func paragraphsRows(showNotificationInfoRow: Bool) -> [CVRow] {
        var rows: [CVRow] = []
        if showNotificationInfoRow {
            let didAlreadyReceiveAStatus: Bool = RBManager.shared.lastStatusReceivedDate != nil
            let notificationRow: CVRow = CVRow(title: "myHealthController.notification.title".localized,
                                               subtitle: "myHealthController.notification.subtitle".localized,
                                               xibName: .paragraphCell,
                                               theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                  topInset: didAlreadyReceiveAStatus ? 20.0 : 10.0,
                                                                  bottomInset: 10.0,
                                                                  textAlignment: .left,
                                                                  titleFont: { Appearance.Cell.Text.headTitleFont }))
            rows.append(notificationRow)
        }
        let advicesRow: CVRow = CVRow(title: "myHealthController.covidAdvices.title".localized,
                                      subtitle: "myHealthController.covidAdvices.subtitle".localized,
                                      buttonTitle: "myHealthController.covidAdvices.buttonTitle".localized,
                                      xibName: .paragraphCell,
                                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                         topInset: showNotificationInfoRow ? 10.0 : 20.0,
                                                         textAlignment: .left,
                                                         titleFont: { Appearance.Cell.Text.headTitleFont }),
                                      selectionAction: {
                                          URL(string: "myHealthController.covidAdvices.url".localized)?.openInSafari()
                                      })
        rows.append(advicesRow)
        let testingRow: CVRow = CVRow(title: "myHealthController.testingSites.title".localized,
                                      subtitle: "myHealthController.testingSites.subtitle".localized,
                                      buttonTitle: "myHealthController.testingSites.buttonTitle".localized,
                                      xibName: .paragraphCell,
                                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                         topInset: 10.0,
                                                         bottomInset: 10.0,
                                                         textAlignment: .left,
                                                         titleFont: { Appearance.Cell.Text.headTitleFont }),
                                      selectionAction: {
                                          URL(string: "myHealthController.testingSites.url".localized)?.openInSafari()
                                })
        rows.append(testingRow)
        let departmentRow: CVRow = CVRow(title: "myHealthController.yourDepartment.title".localized,
                                         subtitle: "myHealthController.yourDepartment.subtitle".localized,
                                         buttonTitle: "myHealthController.yourDepartment.buttonTitle".localized,
                                         xibName: .paragraphCell,
                                         theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                            topInset: 10.0,
                                                            bottomInset: 10.0,
                                                            textAlignment: .left,
                                                            titleFont: { Appearance.Cell.Text.headTitleFont }),
                                         selectionAction: {
                                          URL(string: "myHealthController.yourDepartment.url".localized)?.openInSafari()
                                    })
        rows.append(departmentRow)
        return rows
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
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didTouchAboutButton() {
        didTouchAbout()
    }
    
    @objc private func statusDataChanged() {
        reloadUI()
        updateBadge()
    }
    
    private func updateBadge() {
        navigationChildController?.tabBarItem.badgeValue = RBManager.shared.isAtRisk ? "1" : nil
    }
    
    private func didTouchMoreButton() {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "myHealthController.alert.atitudeToAdopt".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchReadMore()
        }))
        alertController.addAction(UIAlertAction(title: "sickController.state.deleteNotification".localized, style: .destructive, handler: { [weak self] _ in
            self?.showNotificationDeletionAlert()
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    
    private func didTouchReadMoreButton() {
        didTouchReadMore()
    }
    
    private func showNotificationDeletionAlert() {
        let alertController: UIAlertController = UIAlertController(title: "sickController.state.deleteNotification.alert.title".localized, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "common.yes".localized, style: .destructive, handler: { _ in
            RBManager.shared.clearAtRiskAlert()
        }))
        alertController.addAction(UIAlertAction(title: "common.no".localized, style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func didTouchBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func unregisterButtonPressed() {
        showAlert(title: "manageDataController.quitStopCovid.confirmationDialog.title".localized,
                  message: "manageDataController.quitStopCovid.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized, handler:  {
                    switch ParametersManager.shared.apiVersion {
                    case .v3, .v4:
                        HUD.show(.progress)
                        RBManager.shared.unregisterV3 { [weak self] error, isErrorBlocking in
                            HUD.hide()
                            if error != nil && isErrorBlocking {
                                self?.showAlert(title: "common.error".localized,
                                                message: "common.error.server".localized,
                                                okTitle: "common.ok".localized)
                            } else {
                                KeyFiguresManager.shared.currentPostalCode = nil
                                AttestationsManager.shared.clearAllData()
                                VenuesManager.shared.clearAllData()
                                NotificationCenter.default.post(name: .changeAppState, object: RootCoordinator.State.onboarding, userInfo: nil)
                            }
                        }
                    }
                  })
    }

}

extension SickController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
