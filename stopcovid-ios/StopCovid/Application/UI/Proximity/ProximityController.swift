// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ProximityController.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class ProximityController: CVTableViewController {
    
    var canActivateProximity: Bool { areNotificationsAuthorized == true && BluetoothStateManager.shared.isAuthorized && BluetoothStateManager.shared.isActivated }
    private let showCaptchaChallenge: (_ captcha: Captcha, _ didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), _ didCancelCaptcha: @escaping () -> ()) -> ()
    private let didTouchManageData: () -> ()
    private let didTouchPrivacy: () -> ()
    private let didTouchAbout: () -> ()
    private var didFinishLoad: (() -> ())?
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
         didTouchManageData: @escaping () -> (),
         didTouchPrivacy: @escaping () -> (),
         didFinishLoad: (() -> ())?,
         deinitBlock: @escaping () -> ()) {
        self.didTouchAbout = didTouchAbout
        self.didTouchManageData = didTouchManageData
        self.didTouchPrivacy = didTouchPrivacy
        self.showCaptchaChallenge = showCaptchaChallenge
        self.didFinishLoad = didFinishLoad
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
        title = isActivated ? "common.bravo".localized : "common.warning".localized
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
        if !areNotificationsAuthorized && !BluetoothStateManager.shared.isAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotificationsOrBluetooth".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized)
        } else if !areNotificationsAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noNotifications".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized)
        } else if !BluetoothStateManager.shared.isAuthorized {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBluetooth".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor,
                                                            actionHint: "accessibility.hint.proximity.alert.touchToGoToSettings.ios".localized)
        } else if !BluetoothStateManager.shared.isActivated {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.bluetoothOff".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor)
        } else if !RBManager.shared.isProximityActivated {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.activateProximity".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor)
        } else if UIApplication.shared.backgroundRefreshStatus == .denied {
            bottomMessageContainerController?.updateMessage(text: "proximityController.error.noBackgroundAppRefresh".localized,
                                                            font: messageFont,
                                                            textColor: messageTextColor,
                                                            backgroundColor: messageBackgroundColor)
        } else {
            bottomMessageContainerController?.updateMessage()
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
        let subtitleRow: CVRow = CVRow(title: isActivated ? "proximityController.switch.subtitle.activated".localized : "proximityController.switch.subtitle.deactivated".localized,
                                       xibName: .textCell,
                                       theme: CVRow.Theme(topInset: 0.0,
                                                          bottomInset: 20.0,
                                                          textAlignment: .natural,
                                                          titleFont: { Appearance.Cell.Text.standardBigFont },
                                                          separatorLeftInset: nil))
        rows.append(subtitleRow)
        let stateRow: CVRow = CVRow(xibName: .stateAnimationCell,
                                    theme: CVRow.Theme(separatorLeftInset: nil),
                                    willDisplay: { [weak self] cell in
                                        self?.stateCell = cell as? StateAnimationCell
                                        if self?.wasActivated == true {
                                            self?.stateCell?.setOn(animated: false)
                                        } else {
                                            self?.stateCell?.setOff(animated: false)
                                        }
        })
        rows.append(stateRow)
        let activationButtonRow: CVRow = CVRow(title: isActivated ? "proximityController.button.deactivateProximity".localized : "proximityController.button.activateProximity".localized,
                                               xibName: .buttonCell,
                                               theme: CVRow.Theme(topInset: 20.0, bottomInset: 20.0, buttonStyle: isActivated ? .secondary : .primary),
                                               enabled: canActivateProximity,
                                               selectionAction: { [weak self] in
                                                guard let self = self else { return }
                                                self.didChangeSwitchValue(isOn: !self.isActivated)
        })
        rows.append(activationButtonRow)
        let textRow: CVRow = CVRow(subtitle: isActivated ? "proximityController.mainMessage.subtitle.on".localized : "proximityController.mainMessage.subtitle.off".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 0.0, bottomInset: 20.0, textAlignment: .natural, separatorLeftInset: Appearance.Cell.leftMargin))
        rows.append(textRow)
        let privacyRow: CVRow = CVRow(title: "privacyController.tabBar.title".localized,
                                      image: Asset.Images.privacy.image,
                                      xibName: .standardCell,
                                      theme: CVRow.Theme(topInset: 15.0,
                                                         bottomInset: 15.0,
                                                         textAlignment: .natural,
                                                         titleFont: { Appearance.Cell.Text.standardFont },
                                                         titleColor: Asset.Colors.tint.color,
                                                         imageTintColor: Appearance.Cell.Image.tintColor,
                                                         imageSize: Appearance.Cell.Image.size,
                                                         separatorLeftInset: Appearance.Cell.leftMargin),
                                      selectionAction: { [weak self] in
                                        self?.didTouchPrivacy()
            }, willDisplay: { cell in
                cell.cvTitleLabel?.accessibilityTraits = .button
        })
        rows.append(privacyRow)
        let manageDataRow: CVRow = CVRow(title: "proximityController.manageData".localized,
                                         image: Asset.Images.manageData.image,
                                         xibName: .standardCell,
                                         theme: CVRow.Theme(topInset: 15.0,
                                                            bottomInset: 15.0,
                                                            textAlignment: .natural,
                                                            titleFont: { Appearance.Cell.Text.standardFont },
                                                            titleColor: Asset.Colors.tint.color,
                                                            imageTintColor: Appearance.Cell.Image.tintColor,
                                                            imageSize: Appearance.Cell.Image.size,
                                                            separatorLeftInset: 0.0),
                                         selectionAction: { [weak self] in
                                            self?.didTouchManageData()
            }, willDisplay: { cell in
                cell.cvTitleLabel?.accessibilityTraits = .button
        })
        rows.append(manageDataRow)
        rows.append(.empty)
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
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationChildController?.updateRightBarButtonItem(UIBarButtonItem(title: "common.about".localized, style: .plain, target: self, action: #selector(didTouchAboutButton)))
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
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        BluetoothStateManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func didChangeSwitchValue(isOn: Bool) {
        guard !isChangingState else { return }
        isChangingState = true
        if isOn {
            if RBManager.shared.isRegistered {
                if RBManager.shared.currentEpoch == nil {
                    processStatusV3()
                } else {
                    processRegistrationDone()
                    isChangingState = false
                }
            } else {
                HUD.show(.progress)
                ParametersManager.shared.fetchConfig { result in
                    HUD.hide()
                    self.processRegisterWithCaptcha {
                        self.isChangingState = false
                    }
                }
            }
        } else {
            RBManager.shared.isProximityActivated = false
            RBManager.shared.stopProximityDetection()
            isChangingState = false
        }
    }
    
    private func processRegisterWithCaptcha(_ completion: @escaping () -> ()) {
        HUD.show(.progress)
        generateCaptcha { result in
            HUD.hide()
            switch result {
            case let .success(captcha):
                self.showCaptchaChallenge(captcha, { id, answer in
                    switch ParametersManager.shared.apiVersion {
                    case .v2:
                        self.processRegisterV2(answer: answer, captchaId: id, completion: completion)
                    case .v3:
                        self.processRegisterV3(answer: answer, captchaId: id, completion: completion)
                    }
                }, { [weak self] in
                    self?.isChangingState = false
                })
            case .failure:
                self.showAlert(title: "common.error".localized,
                               message: "common.error.server".localized,
                               okTitle: "common.retry".localized,
                               cancelTitle: "common.cancel".localized, handler: { [weak self] in
                                self?.didChangeSwitchValue(isOn: true)
                })
                completion()
            }
        }
    }
    
    private func processStatus() {
        HUD.show(.progress)
        RBManager.shared.status { error in
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
                self.processRegistrationDone()
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
                self.processRegistrationDone()
            }
        }
    }
    
    private func processRegisterV2(answer: String, captchaId: String, completion: @escaping () -> ()) {
        HUD.show(.progress)
        RBManager.shared.registerV2(captcha: answer, captchaId: captchaId) { error in
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
                self.processRegistrationDone()
            }
            completion()
        }
    }
    
    private func processRegisterV3(answer: String, captchaId: String, completion: @escaping () -> ()) {
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
                self.processRegistrationDone()
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
    
    @objc private func didTouchAboutButton() {
        didTouchAbout()
    }
    
    @objc private func appDidBecomeActive() {
        updateNotificationsState {
            self.updateUIForAuthorizationChange()
        }
    }
    
    @objc private func statusDataChanged() {
        updateUIForAuthorizationChange()
    }
    
    private func setInteractiveRecognizer() {
        guard let navigationController = navigationController else { return }
        popRecognizer = InteractivePopGestureRecognizer(controller: navigationController)
        navigationController.interactivePopGestureRecognizer?.delegate = popRecognizer
    }

}

extension ProximityController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension ProximityController: BluetoothStateObserver {
    
    func bluetoothStateDidUpdate() {
        if !BluetoothStateManager.shared.isUnknown && areNotificationsAuthorized != nil {
            isWaitingForNeededInfo = false
        }
        updateUIForAuthorizationChange()
    }
    
}
