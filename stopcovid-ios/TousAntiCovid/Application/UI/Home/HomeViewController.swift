// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  HomeViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class HomeViewController: CVTableViewController {
    
    var canActivateProximity: Bool { areNotificationsAuthorized == true && BluetoothStateManager.shared.isAuthorized && BluetoothStateManager.shared.isActivated }
    private let showCaptchaChallenge: (_ captcha: Captcha, _ didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), _ didCancelCaptcha: @escaping () -> ()) -> ()
    private let didTouchDocument: () -> ()
    private let didTouchManageData: () -> ()
    private let didTouchPrivacy: () -> ()
    private let didTouchAbout: () -> ()
    private var didFinishLoad: (() -> ())?
    private var didTouchSupport: (() -> ())?
    private var didTouchHealth: () -> ()
    private var didTouchInfo: () -> ()
    private var didTouchKeyFigures: () -> ()
    private var didTouchDeclare: () -> ()
    private var didTouchUsefulLinks: () -> ()
    private var didTouchRecordVenues: () -> ()
    private var didTouchPrivateEvents: () -> ()
    private var didTouchVenuesHistory: () -> ()
    private var didRecordVenue: (_ url: URL) -> ()
    private(set) var didTouchOpenIsolationForm: () -> ()
    private let deinitBlock: () -> ()
    
    private var popRecognizer: InteractivePopGestureRecognizer?
    private var initialContentOffset: CGFloat?
    private var isActivated: Bool { canActivateProximity && RBManager.shared.isProximityActivated }
    private var wasActivated: Bool = false
    private var isChangingState: Bool = false
    
    private var areNotificationsAuthorized: Bool?
    private weak var stateCell: StateAnimationCell?
    private var isWaitingForNeededInfo: Bool = true

    init(didTouchAbout: @escaping () -> (),
         showCaptchaChallenge: @escaping (_ captcha: Captcha, _ didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), _ didCancelCaptcha: @escaping () -> ()) -> (),
         didTouchDocument: @escaping () -> (),
         didTouchManageData: @escaping () -> (),
         didTouchPrivacy: @escaping () -> (),
         didFinishLoad: (() -> ())?,
         didTouchSupport: (() -> ())? = nil,
         didTouchHealth: @escaping () -> (),
         didTouchInfo: @escaping () -> (),
         didTouchKeyFigures: @escaping () -> (),
         didTouchDeclare: @escaping () -> (),
         didTouchUsefulLinks: @escaping () -> (),
         didTouchRecordVenues: @escaping () -> (),
         didTouchPrivateEvents: @escaping () -> (),
         didTouchVenuesHistory: @escaping () -> (),
         didRecordVenue: @escaping (_ url: URL) -> (),
         didTouchOpenIsolationForm: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchDocument = didTouchDocument
        self.didTouchAbout = didTouchAbout
        self.didTouchManageData = didTouchManageData
        self.didTouchPrivacy = didTouchPrivacy
        self.showCaptchaChallenge = showCaptchaChallenge
        self.didFinishLoad = didFinishLoad
        self.didTouchSupport = didTouchSupport
        self.didTouchHealth = didTouchHealth
        self.didTouchInfo = didTouchInfo
        self.didTouchKeyFigures = didTouchKeyFigures
        self.didTouchDeclare = didTouchDeclare
        self.didTouchUsefulLinks = didTouchUsefulLinks
        self.didTouchRecordVenues = didTouchRecordVenues
        self.didTouchPrivateEvents = didTouchPrivateEvents
        self.didTouchVenuesHistory = didTouchVenuesHistory
        self.didRecordVenue = didRecordVenue
        self.didTouchOpenIsolationForm = didTouchOpenIsolationForm
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initBottomMessageContainer()
        addObserver()
        setInteractiveRecognizer()
        wasActivated = RBManager.shared.isProximityActivated
        if !RBManager.shared.isRegistered {
            areNotificationsAuthorized = true
            isWaitingForNeededInfo = false
            updateUIForAuthorizationChange()
        }
        updateNotificationsState {
            self.updateUIForAuthorizationChange()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initInitialContentOffset()
        stateCell?.continuePlayingIfNeeded()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func initInitialContentOffset() {
        if initialContentOffset == nil {
            initialContentOffset = tableView.contentOffset.y
        }
    }
    
    private func updateTitle() {
        title = isActivated ? "home.title.activated".localized : "home.title.deactivated".localized
        navigationChildController?.updateTitle(title)
    }
    
    private func updateNotificationsState(_ completion: (() -> ())? = nil) {
        NotificationsManager.shared.areNotificationsAuthorized { notificationsAuthorized in
            self.areNotificationsAuthorized = notificationsAuthorized
            if !BluetoothStateManager.shared.isUnknown {
                self.isWaitingForNeededInfo = false
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func updateUIForAuthorizationChange() {
        guard let areNotificationsAuthorized = areNotificationsAuthorized, !isWaitingForNeededInfo else { return }
        let messageFont: UIFont? = Appearance.BottomMessage.font
        let messageTextColor: UIColor = .black
        let messageBackgroundColor: UIColor = Asset.Colors.info.color
        if !RBManager.shared.canReactivateProximity {
            bottomMessageContainerController?.updateMessage { [weak self] in self?.updateTableViewBottomInset() }
        } else if !areNotificationsAuthorized && !BluetoothStateManager.shared.isAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotificationsOrBluetooth".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if !areNotificationsAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotifications".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if !BluetoothStateManager.shared.isAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBluetooth".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if !BluetoothStateManager.shared.isActivated {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.bluetoothOff".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor) {
                [weak self] in self?.updateTableViewBottomInset()
            }
        } else if !RBManager.shared.isProximityActivated {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.activateProximity".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else if UIApplication.shared.backgroundRefreshStatus == .denied {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBackgroundAppRefresh".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor) { [weak self] in
                self?.updateTableViewBottomInset()
            }
        } else {
            bottomMessageContainerController?.updateMessage { [weak self] in self?.updateTableViewBottomInset() }
        }
        updateTitle()
        reloadUI(animated: true) {
            if self.wasActivated != self.isActivated {
                self.wasActivated = self.isActivated
                if self.isActivated == true {
                    self.stateCell?.setOn()
                } else {
                    self.stateCell?.setOff()
                }
            }
            self.didFinishLoad?()
            self.didFinishLoad = nil
        }
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let titleRow: CVRow = CVRow.titleRow(title: title) { [weak self] cell in
            self?.navigationChildController?.updateLabel(titleLabel: cell.cvTitleLabel, containerView: cell)
        }
        rows.append(titleRow)
        let stateRow: CVRow = CVRow(xibName: .stateAnimationCell,
                                    theme: CVRow.Theme(topInset: 30.0, separatorLeftInset: nil),
                                    willDisplay: { [weak self] cell in
                                        self?.stateCell = cell as? StateAnimationCell
                                        if self?.wasActivated == true {
                                            self?.stateCell?.setOn(animated: false)
                                        } else {
                                            self?.stateCell?.setOff(animated: false)
                                        }
        })
        rows.append(stateRow)
        rows.append(activationButtonRow(isRegistered: RBManager.shared.isRegistered))
        rows.append(contentsOf: healthSectionRows(isAtRisk: RBManager.shared.isAtRisk))
        if !RBManager.shared.isSick && VenuesManager.shared.isVenuesRecordingActivated {
            rows.append(contentsOf: venuesSectionRows())
        }
        rows.append(contentsOf: infoSectionRows())
        if ParametersManager.shared.displayAttestation {
            rows.append(contentsOf: attestationSectionRows())
        }
        rows.append(contentsOf: moreSectionRows())
        return rows
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if canActivateProximity && RBManager.shared.isProximityActivated {
            let distance: CGFloat = abs((initialContentOffset ?? 0.0) - tableView.contentOffset.y) + (tableView.tableFooterView?.frame.height ?? 0.0)
            if tableView.contentInset.bottom != 0.0 && distance < tableView.contentInset.bottom {
                tableView.contentInset.bottom = 0.0
            }
        }
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        updateTableViewBottomInset()
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.canCancelContentTouches = true
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func updateTableViewBottomInset() {
        let bottomSafeArea: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: max(bottomMessageContainerController?.messageHeight ?? bottomSafeArea, bottomSafeArea) + 20.0))
    }
    
    private func initBottomMessageContainer() {
        bottomMessageContainerController?.messageDidTouch = { [weak self] in
            guard let self = self else { return }
            if self.canActivateProximity {
                if UIApplication.shared.backgroundRefreshStatus == .denied {
                    UIApplication.shared.openSettings()
                } else {
                    self.didChangeSwitchValue(isOn: true)
                }
            } else if self.areNotificationsAuthorized != true || !BluetoothStateManager.shared.isAuthorized {
                UIApplication.shared.openSettings()
            }
        }
    }
    
    private func addObserver() {
        LocalizationsManager.shared.addObserver(self)
        BluetoothStateManager.shared.addObserver(self)
        InfoCenterManager.shared.addObserver(self)
        KeyFiguresManager.shared.addObserver(self)
        AttestationsManager.shared.addObserver(self)
        IsolationManager.shared.addObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(widgetDidRequestRegister), name: .widgetDidRequestRegister, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTouchProximityReactivationNotification), name: .didTouchProximityReactivationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openFullVenueRecordingFlowFromDeeplink), name: .openFullVenueRecordingFlowFromDeeplink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newVenueRecordingFromDeeplink(_:)), name: .newVenueRecordingFromDeeplink, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        BluetoothStateManager.shared.removeObserver(self)
        InfoCenterManager.shared.removeObserver(self)
        KeyFiguresManager.shared.removeObserver(self)
        IsolationManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func didTouchIsSickReadMore() {
        showAlert(title: "home.activation.sick.alert.title".localized,
                  message: "home.activation.sick.alert.message".localized,
                  okTitle: "common.ok".localized)
    }
    
    private func didChangeSwitchValue(isOn: Bool) {
        guard !isChangingState else { return }
        isChangingState = true
        if isOn {
            cancelReactivationReminder()
            if RBManager.shared.isRegistered {
                if RBManager.shared.currentEpoch == nil {
                    processStatusV3()
                } else {
                    processRegistrationDone()
                    isChangingState = false
                }
            } else {
                HUD.show(.progress)
                ConfigManager.shared.fetch { result in
                    HUD.hide()
                    self.processRegisterWithCaptcha { _ in
                        self.isChangingState = false
                    }
                }
            }
        } else {
            RBManager.shared.isProximityActivated = false
            RBManager.shared.stopProximityDetection()
            isChangingState = false
            showDeactivationReminderActionSheet()
        }
    }
    
    private func processOnlyRegistrationIfNeeded(_ completion: @escaping (_ error: Error?) -> ()) {
        if RBManager.shared.isRegistered {
            completion(nil)
        } else {
            processRegisterWithCaptcha(activateProximityAfterRegistration: false) { error in
                self.reloadUI(animated: true)
                completion(error)
            }
        }
    }
    
    private func processRegisterWithCaptcha(activateProximityAfterRegistration: Bool = true, completion: @escaping (_ error: Error?) -> ()) {
        HUD.show(.progress)
        generateCaptcha { result in
            HUD.hide()
            switch result {
            case let .success(captcha):
                self.showCaptchaChallenge(captcha, { id, answer in
                    self.processRegisterV3(answer: answer, captchaId: id, activateProximityAfterRegistration: activateProximityAfterRegistration) {
                        completion(nil)
                    }
                }, { [weak self] in
                    self?.isChangingState = false
                })
            case let .failure(error):
                self.showAlert(title: "common.error".localized,
                               message: "common.error.server".localized,
                               okTitle: "common.retry".localized,
                               cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                self?.didChangeSwitchValue(isOn: true)
                })
                completion(error)
            }
        }
    }
    
    private func processStatusV3() {
        HUD.show(.progress)
        RBManager.shared.statusV3 { error in
            HUD.hide()
            self.isChangingState = false
            if let error = error {
                if (error as NSError).code == -1 {
                    self.showAlert(title: "common.error.clockNotAligned.title".localized,
                                   message: "common.error.clockNotAligned.message".localized,
                                   okTitle: "common.ok".localized)
                } else {
                    self.showAlert(title: "common.error".localized,
                                   message: "common.error.server".localized,
                                   okTitle: "common.ok".localized)
                }
            } else {
                NotificationsManager.shared.scheduleUltimateNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
                self.processRegistrationDone()
            }
        }
        if VenuesManager.shared.isVenuesRecordingActivated {
            VenuesManager.shared.status()
        }
    }
    
    private func processRegisterV3(answer: String, captchaId: String, activateProximityAfterRegistration: Bool = true, completion: @escaping () -> ()) {
        HUD.show(.progress)
        RBManager.shared.registerV3(captcha: answer, captchaId: captchaId) { error in
            HUD.hide()
            if let error = error {
                if (error as NSError).code == -1 {
                    self.showAlert(title: "common.error.clockNotAligned.title".localized,
                                   message: "common.error.clockNotAligned.message".localized,
                                   okTitle: "common.ok".localized)
                } else if (error as NSError).code == 401 {
                    self.showAlert(title: "captchaController.alert.invalidCode.title".localized,
                                   message: "captchaController.alert.invalidCode.message".localized,
                                   okTitle: "common.retry".localized,
                                   cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                    self?.didChangeSwitchValue(isOn: true)
                    })
                } else {
                    self.showAlert(title: "common.error".localized,
                                   message: "common.error.server".localized,
                                   okTitle: "common.retry".localized,
                                   cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                    self?.didChangeSwitchValue(isOn: true)
                    })
                }
            } else {
                if activateProximityAfterRegistration {
                    self.processRegistrationDone()
                }
            }
            completion()
        }
    }
    
    private func generateCaptcha(_ completion: @escaping (_ result: Result<Captcha, Error>) -> ()) {
        if UIAccessibility.isVoiceOverRunning {
            CaptchaManager.shared.generateCaptchaAudio { result in
                completion(result)
            }
        } else {
            CaptchaManager.shared.generateCaptchaImage { result in
                completion(result)
            }
        }
    }
    
    private func processRegistrationDone() {
        RBManager.shared.isProximityActivated = true
        RBManager.shared.startProximityDetection()
    }
    
    @objc private func appDidBecomeActive() {
        updateNotificationsState {
            self.updateUIForAuthorizationChange()
        }
    }
    
    @objc private func statusDataChanged() {
        updateUIForAuthorizationChange()
    }
    
    @objc private func widgetDidRequestRegister() {
        didChangeSwitchValue(isOn: true)
    }
    
    @objc private func didTouchProximityReactivationNotification() {
        dismiss(animated: true) {
            self.didChangeSwitchValue(isOn: true)
        }
    }
    
    @objc private func openFullVenueRecordingFlowFromDeeplink() {
        processOnlyRegistrationIfNeeded { error in
            guard error == nil else { return }
            self.didTouchRecordVenues()
        }
    }
    
    @objc private func newVenueRecordingFromDeeplink(_ notification: Notification) {
        guard !RBManager.shared.isSick else { return }
        guard VenuesManager.shared.isVenuesRecordingActivated else { return }
        if let url = notification.object as? URL {
            processOnlyRegistrationIfNeeded { error in
                guard error == nil else { return }
                self.didRecordVenue(url)
            }
        } else {
            showVenueRecordingAlertError()
        }
    }
    
    private func showVenueRecordingAlertError() {
        showAlert(title: "venueFlashCodeController.alert.invalidCode.title".localized,
                  message: "venueFlashCodeController.alert.invalidCode.message".localized,
                  okTitle: "common.ok".localized)
    }
    
    private func setInteractiveRecognizer() {
        guard let navigationController = navigationController else { return }
        popRecognizer = InteractivePopGestureRecognizer(controller: navigationController)
        navigationController.interactivePopGestureRecognizer?.delegate = popRecognizer
    }
    
    private func showDeactivationReminderActionSheet() {
        let alertController: UIAlertController = UIAlertController(title: "home.deactivate.actionSheet.title".localized,
                                                                   message: "home.deactivate.actionSheet.subtitle".localized,
                                                                   preferredStyle: .actionSheet)
        ParametersManager.shared.proximityReactivationReminderHours.forEach { hours in
            let hoursString: String = hours == 1 ? "home.deactivate.actionSheet.hours.singular" : "home.deactivate.actionSheet.hours.plural"
            alertController.addAction(UIAlertAction(title: String(format: hoursString.localized, Int(hours)), style: .default) { [weak self] _ in
                let hoursToUse: Double = Double(hours)
                self?.triggerReactivationReminder(hours: hoursToUse)
            })
        }
        alertController.addAction(UIAlertAction(title: "home.deactivate.actionSheet.noReminder".localized, style: .cancel) { [weak self] _ in
            self?.cancelReactivationReminder()
        })
        present(alertController, animated: true)
    }
    
    private func triggerReactivationReminder(hours: Double) {
        NotificationsManager.shared.scheduleProximityReactivationNotification(hours: hours)
    }
    
    private func cancelReactivationReminder() {
        NotificationsManager.shared.cancelProximityReactivationNotification()
    }

}

extension HomeViewController {
    
    private func activationButtonRow(isRegistered: Bool) -> CVRow {
        if isRegistered {
            let activationTitle: String = isActivated ? "home.mainButton.deactivate".localized : "home.mainButton.activate".localized
            let activationButtonRow: CVRow = CVRow(title: RBManager.shared.canReactivateProximity ? activationTitle : "common.readMore".localized,
                                                   xibName: .buttonCell,
                                                   theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0, buttonStyle: isActivated ? .secondary : .primary),
                                                   enabled: canActivateProximity,
                                                   selectionAction: { [weak self] in
                                                    guard let self = self else { return }
                                                    if RBManager.shared.canReactivateProximity {
                                                        self.didChangeSwitchValue(isOn: !self.isActivated)
                                                    } else {
                                                        self.didTouchIsSickReadMore()
                                                    }
            })
            return activationButtonRow
        } else {
            let activationButtonRow: CVRow = CVRow(title: isActivated ? "home.mainButton.deactivate".localized : "home.mainButton.activate".localized,
                                                   subtitle: "home.activationExplanation".localized,
                                                   xibName: .activationButtonCell,
                                                   theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                      topInset: 0.0,
                                                                      bottomInset: 0.0,
                                                                      textAlignment: .natural,
                                                                      buttonStyle: isActivated ? .secondary : .primary),
                                                   enabled: canActivateProximity,
                                                   selectionAction: { [weak self] in
                                                    guard let self = self else { return }
                                                    self.didChangeSwitchValue(isOn: !self.isActivated)
                                                   })
            return activationButtonRow
        }
    }
    
    private func healthSectionRows(isAtRisk: Bool) -> [CVRow] {
        var rows: [CVRow] = []
        
        let showHealth: Bool = RBManager.shared.lastStatusReceivedDate != nil || RBManager.shared.isSick
        let showDeclare: Bool = RBManager.shared.isRegistered && !RBManager.shared.isSick
        
        if showHealth {
            let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
            let notificationDateString: String = notificationDate?.relativelyFormatted() ?? "N/A"
            
            let header: String? = RBManager.shared.isSick ? nil : notificationDateString
            let title: String
            let subtitle: String?
            let startColor: UIColor
            let endColor: UIColor
            
            if RBManager.shared.isSick {
                title = "home.healthSection.isSick.standaloneTitle".localized
                subtitle = nil
                startColor = Asset.Colors.gradientStartBlue.color
                endColor = Asset.Colors.gradientEndBlue.color
            } else if isAtRisk {
                title = "home.healthSection.contact.cellTitle".localized
                subtitle = "home.healthSection.contact.cellSubtitle".localized
                startColor = Asset.Colors.gradientStartRed.color
                endColor = Asset.Colors.gradientEndRed.color
            } else if VenuesManager.shared.lastWarningRiskReceivedDate != nil {
                title = "home.healthSection.warningContact.cellTitle".localized
                subtitle = "home.healthSection.warningContact.cellSubtitle".localized
                startColor = Asset.Colors.gradientStartOrange.color
                endColor = Asset.Colors.gradientEndOrange.color
            } else {
                title = "home.healthSection.noContact.cellTitle".localized
                subtitle = "home.healthSection.noContact.cellSubtitle".localized
                startColor = Asset.Colors.gradientStartGreen.color
                endColor = Asset.Colors.gradientEndGreen.color
            }
            let contactStatusRow: CVRow = CVRow(title: title,
                                                subtitle: subtitle,
                                                accessoryText: header,
                                                image: Asset.Images.healthCard.image,
                                                xibName: .contactStatusCell,
                                                theme: CVRow.Theme(topInset: 0.0,
                                                                   bottomInset: (RBManager.shared.isSick && !ParametersManager.shared.displayIsolation) ? 0.0 : Appearance.Cell.leftMargin,
                                                                   textAlignment: .natural,
                                                                   titleColor: .white,
                                                                   subtitleColor: .white),
                                                associatedValue: (startColor, endColor),
                                                selectionAction: { [weak self] in
                                                    self?.didTouchHealth()
                                                }, willDisplay: { cell in
                                                    cell.selectionStyle = .none
                                                    cell.accessoryType = .none
                                                })
            rows.append(contactStatusRow)
        }
        if ParametersManager.shared.displayIsolation {
            rows.append(contentsOf: isolationRows(isLastSectionBlock: !showDeclare))
        }
        if showDeclare {
            let declareRow: CVRow = CVRow(title: "home.declareSection.cellTitle".localized,
                                          subtitle: "home.declareSection.cellSubtitle".localized,
                                          image: Asset.Images.declareCard.image,
                                          xibName: .declareCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 0.0,
                                                             bottomInset: 0.0,
                                                             textAlignment: .natural),
                                          selectionAction: { [weak self] in
                                            self?.didTouchDeclare()
                                          }, willDisplay: { cell in
                                            cell.selectionStyle = .none
                                            cell.accessoryType = .none
                                          })
            
            rows.append(declareRow)
        }
        if !rows.isEmpty {
            let healthSectionRow: CVRow = CVRow(title: "home.healthSection.title".localized,
                                                xibName: .textCell,
                                                theme: CVRow.Theme(topInset: 30.0,
                                                                   bottomInset: 10.0,
                                                                   textAlignment: .natural,
                                                                   titleFont: { Appearance.Section.titleFont }))
            rows.insert(healthSectionRow, at: 0)
        }
        return rows
    }
    
    private func venuesSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let venuesSectionRow: CVRow = CVRow(title: "home.venuesSection.title".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 10.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Section.titleFont }))
        rows.append(venuesSectionRow)
        let recordRow: CVRow = CVRow(title: "home.venuesSection.recordCell.title".localized,
                                     subtitle: "home.venuesSection.recordCell.subtitle".localized,
                                     image: Asset.Images.shops.image,
                                     xibName: .venueRecordCell,
                                     theme: CVRow.Theme(backgroundColor: Appearance.tintColor,
                                                        topInset: 0.0,
                                                        bottomInset: Appearance.Cell.leftMargin,
                                                        textAlignment: .natural,
                                                        titleColor: Appearance.Button.Primary.titleColor,
                                                        subtitleColor: Appearance.Button.Primary.titleColor),
                                     selectionAction: { [weak self] in
                                        self?.processOnlyRegistrationIfNeeded { error in
                                            guard error == nil else { return }
                                            self?.didTouchRecordVenues()
                                        }
                                     }, willDisplay: { cell in
                                        cell.selectionStyle = .none
                                        cell.accessoryType = .none
                                     })
        rows.append(recordRow)
        if VenuesManager.shared.isPrivateEventsActivated {
            let privateEventRow: CVRow = CVRow(title: "home.venuesSection.privateCell.title".localized,
                                               subtitle: "home.venuesSection.privateCell.subtitle".localized,
                                               image: Asset.Images.parties.image,
                                               xibName: .privateEventCell,
                                               theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                  topInset: 0.0,
                                                                  bottomInset: 0.0,
                                                                  textAlignment: .natural),
                                               selectionAction: { [weak self] in
                                                self?.processOnlyRegistrationIfNeeded { error in
                                                    guard error == nil else { return }
                                                    self?.didTouchPrivateEvents()
                                                }
                                               }, willDisplay: { cell in
                                                cell.selectionStyle = .none
                                                cell.accessoryType = .none
                                               })
            rows.append(privateEventRow)
        }
        return rows
    }
    
    private func infoSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let infoSectionRow: CVRow = CVRow(title: "home.infoSection.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Section.titleFont }))
        rows.append(infoSectionRow)
        
        let highlightedKeyFigure: KeyFigure? = KeyFiguresManager.shared.highlightedKeyFigure
        if let highlightedKeyFigure = highlightedKeyFigure {
            let highlightedKeyFigureRow: CVRow = CVRow(title: ["home.infoSection.newCases".localized, "(\("common.country.france".localized))"].joined(separator: " "),
                                                       subtitle: "keyfigure.dailyUpdates".localized,
                                                       accessoryText: highlightedKeyFigure.valueGlobalToDisplay.formattingValueWithThousandsSeparatorIfPossible(),
                                                       image: Asset.Images.flag.image,
                                                       xibName: .highlightedKeyFigureCell,
                                                       theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                          topInset: 0.0,
                                                                          bottomInset: Appearance.Cell.leftMargin,
                                                                          textAlignment: .natural,
                                                                          titleFont: { Appearance.Cell.Text.titleFont },
                                                                          titleColor: highlightedKeyFigure.color,
                                                                          subtitleFont: { Appearance.Cell.Text.captionTitleFont },
                                                                          subtitleColor: Appearance.Cell.Text.captionTitleColor,
                                                                          accessoryTextFont: { Appearance.Cell.Text.headTitleFont3 },
                                                                          accessoryTextColor: Appearance.Cell.Text.titleColor,
                                                                          imageTintColor: highlightedKeyFigure.color),
                                                       selectionAction: { [weak self] in
                                                          self?.didTouchKeyFigures()
                                                       },
                                                       willDisplay: { cell in
                                                        cell.selectionStyle = .none
                                                        cell.accessoryType = .none
                                                       })
            rows.append(highlightedKeyFigureRow)
        }
        if !KeyFiguresManager.shared.featuredKeyFigures.isEmpty {
            let keyFiguresRow: CVRow = CVRow(title: highlightedKeyFigure == nil ? "home.infoSection.keyFigures".localized : "home.infoSection.otherKeyFigures".localized,
                                             accessoryText: highlightedKeyFigure == nil ? "keyfigure.dailyUpdates".localized : nil,
                                             buttonTitle: "home.infoSection.seeAll".localized,
                                             xibName: .keyFiguresCell,
                                             theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                topInset: 0.0,
                                                                bottomInset: Appearance.Cell.leftMargin,
                                                                textAlignment: .natural),
                                             associatedValue: KeyFiguresManager.shared.featuredKeyFigures,
                                             selectionAction: { [weak self] in
                                                self?.didTouchKeyFigures()
                                             },
                                             willDisplay: { cell in
                                                cell.selectionStyle = .none
                                                cell.accessoryType = .none
                                             })
            rows.append(keyFiguresRow)
        }
        if KeyFiguresManager.shared.displayDepartmentLevel {
            if KeyFiguresManager.shared.currentPostalCode == nil {
                let newPostalCodeRow: CVRow = CVRow(title: "home.infoSection.newPostalCode".localized,
                                                    subtitle: "home.infoSection.newPostalCode.subtitle".localized,
                                                    image: Asset.Images.location.image,
                                                    buttonTitle: "home.infoSection.newPostalCode.button".localized,
                                                    xibName: .newPostalCodeCell,
                                                    theme: CVRow.Theme(backgroundColor: Appearance.Button.Primary.backgroundColor,
                                                                       topInset: 0.0,
                                                                       bottomInset: Appearance.Cell.leftMargin,
                                                                       textAlignment: .natural,
                                                                       titleColor: Appearance.Button.Primary.titleColor,
                                                                       subtitleColor: Appearance.Button.Primary.titleColor,
                                                                       imageTintColor: Appearance.Button.Primary.titleColor),
                                                    selectionAction: { [weak self] in
                                                        self?.didTouchUpdateLocation()
                                                    },
                                                    willDisplay: { cell in
                                                        cell.selectionStyle = .none
                                                        cell.accessoryType = .none
                                                    })
                rows.append(newPostalCodeRow)
            } else {
                let updatePostalCodeRow: CVRow = CVRow(title: "home.infoSection.updatePostalCode".localized,
                                                       image: Asset.Images.location.image,
                                                       xibName: .standardCardCell,
                                                       theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                                           topInset: 0.0,
                                                                           bottomInset: Appearance.Cell.leftMargin,
                                                                           textAlignment: .natural,
                                                                           titleFont: { Appearance.Cell.Text.standardFont },
                                                                           titleColor: Appearance.Cell.Text.headerTitleColor,
                                                                           imageTintColor: Appearance.Cell.Text.headerTitleColor),
                                                       selectionAction: { [weak self] in
                                                        self?.didTouchUpdateLocation()
                                                       },
                                                       willDisplay: { cell in
                                                        cell.selectionStyle = .none
                                                        cell.accessoryType = .none
                                                       })
                rows.append(updatePostalCodeRow)
            }
        }
        if let info = InfoCenterManager.shared.info.sorted(by: { $0.timestamp > $1.timestamp }).first {
            let lastInfoRow: CVRow = CVRow(title: info.title,
                                           subtitle: info.description,
                                           accessoryText: info.formattedDate,
                                           buttonTitle: "home.infoSection.readAll".localized,
                                           xibName: .lastInfoCell,
                                           theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                              topInset: 0.0,
                                                              bottomInset: 0.0,
                                                              textAlignment: .natural),
                                           associatedValue: InfoCenterManager.shared.didReceiveNewInfo,
                                           selectionAction: { [weak self] in
                                            InfoCenterManager.shared.didReceiveNewInfo = false
                                            self?.didTouchInfo()
                                           }, willDisplay: { cell in
                                            cell.selectionStyle = .none
                                            cell.accessoryType = .none
                                           })
            rows.append(lastInfoRow)
        }
        
        return rows
    }
    
    private func attestationSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let attestationSectionRow: CVRow = CVRow(title: "home.attestationSection.title".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 10.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Section.titleFont }))
        rows.append(attestationSectionRow)
        
        let attestationsCount: Int = AttestationsManager.shared.attestations.filter { !$0.isExpired }.count
        let subtitle: String
        switch attestationsCount {
        case 0:
            subtitle = "home.attestationSection.cell.subtitle.noAttestations".localized
        case 1:
            subtitle = "home.attestationSection.cell.subtitle.oneAttestation".localized
        default:
            subtitle = String(format: "home.attestationSection.cell.subtitle.multipleAttestations".localized, attestationsCount)
        }
        
        let attestationRow: CVRow = CVRow(title: "home.attestationSection.cell.title".localized,
                                          subtitle: subtitle,
                                          image: Asset.Images.attestationCard.image,
                                          xibName: .attestationCell,
                                          theme: CVRow.Theme(backgroundColor: Appearance.tintColor,
                                                             topInset: 0.0,
                                                             bottomInset: 0.0,
                                                             textAlignment: .natural,
                                                             titleColor: Appearance.Button.Primary.titleColor,
                                                             subtitleColor: Appearance.Button.Primary.titleColor),
                                          selectionAction: { [weak self] in
                                            self?.didTouchDocument()
                                          }, willDisplay: { cell in
                                            cell.selectionStyle = .none
                                            cell.accessoryType = .none
                                          })
        rows.append(attestationRow)
        return rows
    }
    
    private func didTouchUpdateLocation() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }
    
    private func moreSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let moreSectionRow: CVRow = CVRow(title: "home.moreSection.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 30.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Section.titleFont }))
        rows.append(moreSectionRow)
        
        var menuEntries: [GroupedMenuEntry] = [GroupedMenuEntry(image: Asset.Images.usefulLinks.image,
                                                                title: "home.moreSection.usefulLinks".localized,
                                                                actionBlock: { [weak self] in
                                                                    self?.didTouchUsefulLinks()
                                                                }),
                                               GroupedMenuEntry(image: Asset.Images.bubble.image,
                                                                title: "home.moreSection.appSharing".localized,
                                                                actionBlock: { [weak self] in
                                                                    self?.didTouchShare()
                                                                })]
        
        if VenuesManager.shared.isVenuesRecordingActivated {
            menuEntries.append(GroupedMenuEntry(image: Asset.Images.history.image,
                                                title: "home.moreSection.venuesHistory".localized,
                                                actionBlock: { [weak self] in
                                                    self?.didTouchVenuesHistory()
                                                }))
        }
        
        menuEntries.append(contentsOf: [GroupedMenuEntry(image: Asset.Images.manageData.image,
                                                         title: "home.moreSection.manageData".localized,
                                                         actionBlock: { [weak self] in
                                                             self?.didTouchManageData()
                                                         }),
                                        GroupedMenuEntry(image: Asset.Images.privacy.image,
                                                         title: "home.moreSection.privacy".localized,
                                                         actionBlock: { [weak self] in
                                                             self?.didTouchPrivacy()
                                                         }),
                                        GroupedMenuEntry(image: Asset.Images.about.image,
                                                         title: "home.moreSection.aboutStopCovid".localized,
                                                         actionBlock: { [weak self] in
                                                             self?.didTouchAbout()
                                                         })])
        
        rows.append(contentsOf: menuRowsForEntries(menuEntries))
        return rows
    }
    
    private func menuRowsForEntries(_ entries: [GroupedMenuEntry]) -> [CVRow] {
        let rows: [CVRow] = entries.map {
            var row: CVRow = standardCardRow(title: $0.title, image: $0.image, actionBlock: $0.actionBlock)
            row.theme.imageSize = CGSize(width: 24.0, height: 24.0)
            if $0 == entries.first {
                row.theme.maskedCorners = .top
                row.theme.separatorLeftInset = 2 * Appearance.Cell.leftMargin
                row.theme.separatorRightInset = Appearance.Cell.leftMargin
            } else if $0 == entries.last {
                row.theme.maskedCorners = .bottom
            } else {
                row.theme.maskedCorners = .none
                row.theme.separatorLeftInset = 2 * Appearance.Cell.leftMargin
                row.theme.separatorRightInset = Appearance.Cell.leftMargin
            }
            return row
        }
        return rows
    }
    
    func standardCardRow(title: String, subtitle: String? = nil, image: UIImage, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
                               subtitle: subtitle,
                               image: image,
                               xibName: .standardCardCell,
                               theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                   topInset: 0.0,
                                                   bottomInset: 0.0,
                                                   textAlignment: .natural,
                                                   titleFont: { Appearance.Cell.Text.standardFont },
                                                   titleColor: Appearance.Cell.Text.headerTitleColor,
                                                   imageTintColor: Appearance.Cell.Text.headerTitleColor),
                               selectionAction: {
                                actionBlock()
                               },
                               willDisplay: { cell in
                                cell.selectionStyle = .none
                                cell.accessoryType = .none
                               })
        return row
    }
    
}

extension HomeViewController {
    
    private func didTouchShare() {
        let controller: UIActivityViewController = UIActivityViewController(activityItems: ["sharingController.appSharingMessage".localized], applicationActivities: nil)
        present(controller, animated: true, completion: nil)
    }
    
}

extension HomeViewController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension HomeViewController: BluetoothStateObserver {
    
    func bluetoothStateDidUpdate() {
        if !BluetoothStateManager.shared.isUnknown && areNotificationsAuthorized != nil {
            isWaitingForNeededInfo = false
        }
        updateUIForAuthorizationChange()
    }
    
}

extension HomeViewController: InfoCenterChangesObserver {

    func infoCenterDidUpdate() {
        reloadUI()
    }

}

extension HomeViewController: KeyFiguresChangesObserver {

    func keyFiguresDidUpdate() {
        reloadUI(animated: true)
    }

}

extension HomeViewController: AttestationsChangesObserver {
    
    func attestationsDidUpdate() {
        reloadUI(animated: true)
    }
    
}

extension HomeViewController: IsolationChangesObserver {
    
    func isolationDidUpdate() {
        reloadUI(animated: true)
    }
    
}
