// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class SickController: CVTableViewController {
    
    var didTouchAbout: (() -> ())?
    var didTouchFlash: (() -> ())?
    var didTouchTap: (() -> ())?
    var didTouchReadMore: (() -> ())?
    
    init(didTouchAbout: (() -> ())?, didTouchFlash: (() -> ())?, didTouchTap: (() -> ())?, didTouchReadMore: (() -> ())?) {
        self.didTouchAbout = didTouchAbout
        self.didTouchFlash = didTouchFlash
        self.didTouchTap = didTouchTap
        self.didTouchReadMore = didTouchReadMore
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
        title = RBManager.shared.isSick ? "sickController.sick.title".localized : "sickController.title".localized
        navigationChildController?.updateTitle(title)
    }
    
    override func createRows() -> [CVRow] {
        if RBManager.shared.isSick {
            return sickRows()
        } else {
            if RBManager.shared.lastStatusReceivedDate != nil {
                return RBManager.shared.isAtRisk ? contactRows() : nothingRows()
            } else {
                return startRows()
            }
        }
    }
    
    private func startRows() -> [CVRow] {
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        let imageRow: CVRow = CVRow(image: Asset.Images.diagnosis.image, xibName: .onboardingImageCell)
        return [titleRow, imageRow] + commonRows()
    }
    
    private func contactRows() -> [CVRow] {
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        let imageRow: CVRow = CVRow(image: Asset.Images.diagnosis.image, xibName: .onboardingImageCell)
        
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        
        let notificationDateString: String = String(format: "\("sickController.state.date".localized), %@", notificationDate?.dayMonthFormatted() ?? "N/A", notificationDate?.timeFormatted() ?? "N/A")
        let stateRow: CVRow = CVRow(title: "sickController.state.contact.title".localized,
                                    subtitle: "sickController.state.contact.subtitle".localized,
                                    accessoryText: notificationDateString,
                                    buttonTitle: "common.readMore".localized,
                                    xibName: .sickStateHeaderCell,
                                    theme: CVRow.Theme(backgroundColor: Appearance.Cell.Notification.backgroundColor,
                                                       topInset: 10.0,
                                                       bottomInset: 10.0,
                                                       rightInset: 10.0,
                                                       textAlignment: .natural,
                                                       accessoryTextFont: { Appearance.Cell.Text.accessoryFont },
                                                       separatorLeftInset: 0.0),
                                    selectionAction: { [weak self] in
            self?.didTouchReadMoreButton()
        }, secondarySelectionAction: { [weak self] in
            self?.didTouchMoreButton()
        })
        return [titleRow, imageRow, stateRow] + commonRows()
    }
    
    private func nothingRows() -> [CVRow] {
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        let imageRow: CVRow = CVRow(image: Asset.Images.diagnosis.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(imageRatio: Appearance.Cell.Image.defaultRatio))
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String = String(format: "\("sickController.state.date".localized), %@", notificationDate?.dayMonthFormatted() ?? "N/A", notificationDate?.timeFormatted() ?? "N/A")
        let stateRow: CVRow = CVRow(title: "sickController.state.nothing.title".localized,
                                    subtitle: "sickController.state.nothing.subtitle".localized,
                                    accessoryText: notificationDateString,
                                    buttonTitle: "common.readMore".localized,
                                    xibName: .sickStateHeaderCell,
                                    theme: CVRow.Theme(backgroundColor: Appearance.Cell.Notification.backgroundColor,
                                                       topInset: 10.0,
                                                       bottomInset: 10.0,
                                                       rightInset: 10.0,
                                                       textAlignment: .natural,
                                                       accessoryTextFont: { Appearance.Cell.Text.accessoryFont },
                                                       separatorLeftInset: 0.0),
                                    selectionAction: { [weak self] in
            self?.didTouchReadMoreButton()
        }, secondarySelectionAction: { [weak self] in
            self?.didTouchMoreButton()
        })
        return [titleRow, imageRow, stateRow] + commonRows()
    }
    
    private func sickRows() -> [CVRow] {
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        let imageRow: CVRow = CVRow(image: Asset.Images.sick.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: 20.0))
        let declarationTextRow: CVRow = CVRow(title: "sickController.sick.mainMessage.title".localized,
                                              subtitle: "sickController.sick.mainMessage.subtitle".localized,
                                              xibName: .textCell,
                                              theme: CVRow.Theme(topInset: 40.0, bottomInset: 40.0))
        
        let recommendationsButton: CVRow = CVRow(title: "sickController.button.recommendations".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0, buttonStyle: .primary),
                                        selectionAction: {
            URL(string: "sickController.button.recommendations.url".localized)?.openInSafari()
        })
        let phoneButton: CVRow = CVRow(title: "informationController.step.appointment.buttonTitle".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0, buttonStyle: .primary),
                                            selectionAction: { [weak self] in
            guard let self = self else { return }
            "callCenter.phoneNumber".localized.callPhoneNumber(from: self)
        })
        let unregisterButton: CVRow = CVRow(title: "manageDataController.quitStopCovid.button".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0, buttonStyle: .secondary),
                                            selectionAction: { [weak self] in
            self?.unregisterButtonPressed()
        })
        return [titleRow, imageRow, declarationTextRow, recommendationsButton, phoneButton, unregisterButton]
    }
    
    private func commonRows() -> [CVRow] {
        let textRow: CVRow = CVRow(title: "sickController.message.testedPositive.title".localized,
                                   subtitle: "sickController.message.testedPositive.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 20.0))
        let flashButtonRow: CVRow = CVRow(title: "sickController.button.flash".localized,
                                          xibName: .buttonCell,
                                          theme: CVRow.Theme(topInset: 20.0, bottomInset: 0.0),
                                          selectionAction: { [weak self] in
                                            self?.didTouchFlashButton()
        }, willDisplay: { cell in
            (cell as? ButtonCell)?.button.accessibilityHint = "accessibility.hint.sick.qrCode.enterCodeOnNextButton".localized
        })
        let tapButtonRow: CVRow = CVRow(title: "sickController.button.tap".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 20.0, bottomInset: 20.0, buttonStyle: .secondary),
                                        selectionAction: { [weak self] in
                                            self?.didTouchTapButton()
        })
        return [textRow, flashButtonRow, tapButtonRow]
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationChildController?.updateRightBarButtonItem(UIBarButtonItem(title: "common.about".localized, style: .plain, target: self, action: #selector(didTouchAboutButton)))
    }
    
    private func addObservers() {
        LocalizationsManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didTouchFlashButton() {
        CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
            if granted {
                self.didTouchFlash?()
            } else if !isFirstTimeRequest {
                self.showAlert(title: "scanCodeController.camera.authorizationNeeded.title".localized,
                               message: "scanCodeController.camera.authorizationNeeded.message".localized,
                               okTitle: "common.settings".localized,
                               cancelTitle: "common.cancel".localized) {
                    UIApplication.shared.openSettings()
                }
            }
        }
    }
    
    @objc private func didTouchTapButton() {
        didTouchTap?()
    }
    
    @objc private func didTouchAboutButton() {
        didTouchAbout?()
    }
    
    @objc private func statusDataChanged() {
        reloadUI()
    }
    
    private func didTouchMoreButton() {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "common.readMore".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchReadMore?()
        }))
        alertController.addAction(UIAlertAction(title: "sickController.state.deleteNotification".localized, style: .destructive, handler: { [weak self] _ in
            self?.showNotificationDeletionAlert()
        }))
        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    
    private func didTouchReadMoreButton() {
        didTouchReadMore?()
    }
    
    private func showNotificationDeletionAlert() {
        let alertController: UIAlertController = UIAlertController(title: "sickController.state.deleteNotification.alert.title".localized, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "common.yes".localized, style: .destructive, handler: { _ in
            RBManager.shared.clearAtRiskAlert()
        }))
        alertController.addAction(UIAlertAction(title: "common.no".localized, style: .cancel))
        present(alertController, animated: true, completion: nil)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func unregisterButtonPressed() {
        showAlert(title: "manageDataController.quitStopCovid.confirmationDialog.title".localized,
                  message: "manageDataController.quitStopCovid.confirmationDialog.message".localized,
                  okTitle: "common.yes".localized,
                  isOkDestructive: true,
                  cancelTitle: "common.no".localized) {
            switch ParametersManager.shared.apiVersion {
            case .v3:
                HUD.show(.progress)
                RBManager.shared.unregisterV3 { [weak self] error, isErrorBlocking in
                    HUD.hide()
                    if error != nil && isErrorBlocking {
                        self?.showAlert(title: "common.error".localized,
                                        message: "common.error.server".localized,
                                        okTitle: "common.ok".localized)
                    } else {
                        ParametersManager.shared.clearConfig()
                        NotificationCenter.default.post(name: .changeAppState, object: RootCoordinator.State.onboarding, userInfo: nil)
                    }
                }
            default:
                HUD.show(.progress)
                RBManager.shared.unregister { [weak self] error, isErrorBlocking in
                    HUD.hide()
                    if error != nil && isErrorBlocking {
                        self?.showAlert(title: "common.error".localized,
                                        message: "common.error.server".localized,
                                        okTitle: "common.ok".localized)
                    } else {
                        ParametersManager.shared.clearConfig()
                        NotificationCenter.default.post(name: .changeAppState, object: RootCoordinator.State.onboarding, userInfo: nil)
                    }
                }
            }
        }
    }

}

extension SickController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
