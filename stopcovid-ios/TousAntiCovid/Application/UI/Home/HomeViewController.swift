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
    private let didTouchTestingSites: () -> ()
    private let didTouchCovidAdvices: () -> ()
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
    private var didTouchCovidInfo: () -> ()
    private var didTouchUsefulLinks: () -> ()
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
         didTouchTestingSites: @escaping () -> (),
         didTouchCovidAdvices: @escaping () -> (),
         didTouchDocument: @escaping () -> (),
         didTouchManageData: @escaping () -> (),
         didTouchPrivacy: @escaping () -> (),
         didFinishLoad: (() -> ())?,
         didTouchSupport: (() -> ())? = nil,
         didTouchHealth: @escaping () -> (),
         didTouchInfo: @escaping () -> (),
         didTouchKeyFigures: @escaping () -> (),
         didTouchDeclare: @escaping () -> (),
         didTouchCovidInfo: @escaping () -> (),
         didTouchUsefulLinks: @escaping () -> (),
         deinitBlock: @escaping () -> ()) {
        self.didTouchTestingSites = didTouchTestingSites
        self.didTouchCovidAdvices = didTouchCovidAdvices
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
        self.didTouchCovidInfo = didTouchCovidInfo
        self.didTouchUsefulLinks = didTouchUsefulLinks
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
        if !areNotificationsAuthorized && !BluetoothStateManager.shared.isAuthorized {
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
        if RBManager.shared.lastStatusReceivedDate != nil || RBManager.shared.isSick {
            rows.append(contentsOf: healthSectionRows(isAtRisk: RBManager.shared.isAtRisk))
        }
        rows.append(contentsOf: infoSectionRows())
        rows.append(contentsOf: attestationSectionRows())
        if RBManager.shared.isRegistered && !RBManager.shared.isSick {
            rows.append(contentsOf: declareSectionRows())
        }
        rows.append(contentsOf: sharingSectionRows())
        rows.append(contentsOf: moreSectionRows())
        return rows
    }
    
    private func activationButtonRow(isRegistered: Bool) -> CVRow {
        if isRegistered {
            let activationButtonRow: CVRow = CVRow(title: isActivated ? "home.mainButton.deactivate".localized : "home.mainButton.activate".localized,
                                                   xibName: .buttonCell,
                                                   theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0, buttonStyle: isActivated ? .secondary : .primary),
                                                   enabled: canActivateProximity,
                                                   selectionAction: { [weak self] in
                                                    guard let self = self else { return }
                                                    self.didChangeSwitchValue(isOn: !self.isActivated)
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
        let healthSectionRow: CVRow = CVRow(title: "home.healthSection.title".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 10.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Section.titleFont }))
        rows.append(healthSectionRow)
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String = notificationDate?.relativelyFormatted() ?? "N/A"
        
        let header: String? = RBManager.shared.isSick ? nil : notificationDateString
        let standardtitle: String = isAtRisk ? "home.healthSection.contact.cellTitle".localized : "home.healthSection.noContact.cellTitle".localized
        let standardSubtitle: String = isAtRisk ? "home.healthSection.contact.cellSubtitle".localized : "home.healthSection.noContact.cellSubtitle".localized
        
        let title: String = RBManager.shared.isSick ? "home.healthSection.isSick.standaloneTitle".localized : standardtitle
        let subtitle: String? = RBManager.shared.isSick ? nil : standardSubtitle
        
        let startColor: UIColor = RBManager.shared.isSick ? Asset.Colors.gradientStartBlue.color : (isAtRisk ? Asset.Colors.gradientStartRed.color : Asset.Colors.gradientStartGreen.color)
        let endColor: UIColor = RBManager.shared.isSick ? Asset.Colors.gradientEndBlue.color : (isAtRisk ? Asset.Colors.gradientEndRed.color : Asset.Colors.gradientEndGreen.color)
        
        let contactStatusRow: CVRow = CVRow(title: title,
                                            subtitle: subtitle,
                                            accessoryText: header,
                                            image: Asset.Images.healthCard.image,
                                            xibName: .contactStatusCell,
                                            theme: CVRow.Theme(topInset: 0.0,
                                                               bottomInset: RBManager.shared.isSick ? 0.0 : Appearance.Cell.leftMargin,
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
        if !RBManager.shared.isSick {
            let menuEntries: [GroupedMenuEntry] = [GroupedMenuEntry(image: Asset.Images.search.image,
                                                                    title: "home.moreSection.testingSites".localized,
                                                                    actionBlock: { [weak self] in
                                                                        self?.didTouchTestingSites()
                                                                    }),
                                                   GroupedMenuEntry(image: Asset.Images.bubble.image,
                                                                    title: "home.healthSection.menu.covidAdvices".localized,
                                                                    actionBlock: { [weak self] in
                                                                        self?.didTouchCovidAdvices()
                                                                    })]
            rows.append(contentsOf: menuRowsForEntries(menuEntries))
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

        if !KeyFiguresManager.shared.featuredKeyFigures.isEmpty {
            let keyFiguresRow: CVRow = CVRow(buttonTitle: "home.infoSection.seeAll".localized,
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
                                                              bottomInset: Appearance.Cell.leftMargin,
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
        var row: CVRow = standardCardRow(title: "home.moreSection.covidInfo".localized,
                                         image: Asset.Images.web.image,
                                         actionBlock: { [weak self] in
            self?.didTouchCovidInfo()
        })
        row.theme.imageSize = CGSize(width: 24.0, height: 24.0)
        rows.append(row)
        
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
    
    private func declareSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let declareSectionRow: CVRow = CVRow(title: "home.declareSection.title".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 10.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Section.titleFont }))
        rows.append(declareSectionRow)
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
        return rows
    }
    
    private func sharingSectionRows() -> [CVRow] {
        var rows: [CVRow] = []
        let sharingSectionRow: CVRow = CVRow(title: "home.sharingSection.title".localized,
                                             xibName: .textCell,
                                             theme: CVRow.Theme(topInset: 30.0,
                                                                bottomInset: 10.0,
                                                                textAlignment: .natural,
                                                                titleFont: { Appearance.Section.titleFont }))
        rows.append(sharingSectionRow)
        let sharingRow: CVRow = CVRow(title: "home.sharingSection.cellTitle".localized,
                                      subtitle: "home.sharingSection.cellSubtitle".localized,
                                      image: Asset.Images.shareCard.image,
                                      xibName: .sharingCell,
                                      theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                         topInset: 0.0,
                                                         bottomInset: 0.0,
                                                         textAlignment: .natural),
                                      selectionAction: { [weak self] in
                                        self?.didTouchShare()
                                      }, willDisplay: { cell in
                                        cell.selectionStyle = .none
                                        cell.accessoryType = .none
                                      })
        rows.append(sharingRow)
        return rows
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
        
        let menuEntries: [GroupedMenuEntry] = [GroupedMenuEntry(image: Asset.Images.usefulLinks.image,
                                                                title: "home.moreSection.usefulLinks".localized,
                                                                actionBlock: { [weak self] in
                                                                    self?.didTouchUsefulLinks()
                                                                }),
                                               GroupedMenuEntry(image: Asset.Images.manageData.image,
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
                                                                })]
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
    
    private func standardCardRow(title: String, image: UIImage, actionBlock: @escaping () -> ()) -> CVRow {
        let row: CVRow = CVRow(title: title,
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
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(statusDataChanged), name: .statusDataDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(widgetDidRequestRegister), name: .widgetDidRequestRegister, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTouchProximityReactivationNotification), name: .didTouchProximityReactivationNotification, object: nil)
    }
    
    private func removeObservers() {
        LocalizationsManager.shared.removeObserver(self)
        BluetoothStateManager.shared.removeObserver(self)
        InfoCenterManager.shared.removeObserver(self)
        KeyFiguresManager.shared.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
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
                showDeactivationReminderActionSheet()
        }
    }
    
    private func processRegisterWithCaptcha(_ completion: @escaping () -> ()) {
        HUD.show(.progress)
        generateCaptcha { result in
            HUD.hide()
            switch result {
            case let .success(captcha):
                self.showCaptchaChallenge(captcha, { id, answer in
                    self.processRegisterV3(answer: answer, captchaId: id, completion: completion)
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
