// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MyHealthController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

final class MyHealthController: CVTableViewController {
    
    private let didTouchAbout: () -> ()
    private let didTouchCautionMeasures: () -> ()
    private let didTouchRisksUILevelSectionLink: (RisksUILevelSectionLink?) -> ()
    
    init(didTouchAbout: @escaping () -> (), didTouchCautionMeasures: @escaping () -> (), didTouchRisksUILevelSectionLink: @escaping (RisksUILevelSectionLink?) -> ()) {
        self.didTouchAbout = didTouchAbout
        self.didTouchCautionMeasures = didTouchCautionMeasures
        self.didTouchRisksUILevelSectionLink = didTouchRisksUILevelSectionLink
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
        guard !RBManager.shared.isSick else {
            return sickRows()
        }
        var rows: [CVRow] = [headerRow()]
        if !RBManager.shared.isRegistered {
            rows.append(contentsOf: notRegisteredRows())
        } else if let currentRiskLevel = RisksUIManager.shared.currentLevel {
            if RBManager.shared.lastStatusReceivedDate != nil  {
                rows.append(riskRow(for: currentRiskLevel))
            }
            rows.append(contentsOf: sectionRows(for: currentRiskLevel))
        }
        return rows
    }

    private func riskRow(for currentRiskLevel: RisksUILevel) -> CVRow {
        let notificationDate: Date? = RBManager.shared.lastStatusReceivedDate
        let notificationDateString: String = notificationDate?.relativelyFormatted() ?? "N/A"

        var lastContactDateString: String? = nil
        if let lastContactDateFrom = RisksUIManager.shared.lastContactDateFrom?.dayShortMonthFormatted(), let lastContactDateTo = RisksUIManager.shared.lastContactDateTo?.dayShortMonthYearFormatted() {
            lastContactDateString = String(format: "myHealthStateHeaderCell.exposureDate.range".localized, lastContactDateFrom, lastContactDateTo)
        } else if let lastContactDate = RisksUIManager.shared.lastContactDateFrom?.dayMonthYearFormatted() {
            lastContactDateString = lastContactDate
        }

        let stateRow: CVRow = CVRow(title: currentRiskLevel.labels.detailTitle.localized,
                                    subtitle: currentRiskLevel.labels.detailSubtitle.localized,
                                    accessoryText: notificationDateString,
                                    footerText: lastContactDateString,
                                    xibName: .myHealthStateHeaderCell,
                                    theme: CVRow.Theme(topInset: 0.0,
                                                       bottomInset: 20.0,
                                                       textAlignment: .natural,
                                                       accessoryTextFont: { Appearance.Cell.Text.accessoryFont }),
                                    associatedValue: currentRiskLevel)
        return stateRow
    }
    
    private func sickRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.sick.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: 20.0))
        rows.append(imageRow)
        let declarationTextRow: CVRow = CVRow(title: "myHealthController.sick.mainMessage.title".localized,
                                              subtitle: "myHealthController.sick.mainMessage.subtitle".localized,
                                              xibName: .textCell,
                                              theme: CVRow.Theme(topInset: 40.0, bottomInset: 40.0))
        rows.append(declarationTextRow)
        let recommendationsButton: CVRow = CVRow(title: "myHealthController.button.recommendations".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0),
                                        selectionAction: {
            URL(string: "myHealthController.button.recommendations.url".localized)?.openInSafari()
        })
        rows.append(recommendationsButton)
        let phoneButton: CVRow = CVRow(title: "myHealthController.step.appointment.buttonTitle".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0),
                                            selectionAction: { [weak self] in
            guard let self = self else { return }
            "callCenter.phoneNumber".localized.callPhoneNumber(from: self)
        })
        rows.append(phoneButton)
        let measuresButton: CVRow = CVRow(title: "myHealthController.button.cautionMeasures".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 10.0, bottomInset: 10.0),
                                            selectionAction: { [weak self] in
                                                self?.didTouchCautionMeasures()
        })
        rows.append(measuresButton)
        return rows
    }
    
    private func headerRow() -> CVRow {
        CVRow(image: Asset.Images.diagnosis.image,
              xibName: .imageCell,
              theme: CVRow.Theme(topInset: 20.0,
                                 imageRatio: 375.0 / 233.0))
    }
    
    private func notRegisteredRows() -> [CVRow] {
        let textRow: CVRow = CVRow(title: "myHealthController.notRegistered.mainMessage.title".localized,
                                   subtitle: "myHealthController.notRegistered.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 20.0))
        return [textRow]
    }

    private func sectionRows(for currentRiskLevel: RisksUILevel) -> [CVRow] {
        currentRiskLevel.sections.map { section in
            CVRow(title: section.section.localized,
                  subtitle: section.description.localized,
                  buttonTitle: section.link?.label.localized,
                  xibName: .paragraphCell,
                  theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                     topInset: 0.0,
                                     bottomInset: 20.0,
                                     textAlignment: .left,
                                     titleFont: { Appearance.Cell.Text.headTitleFont }),
                  selectionAction: { [weak self] in
                    self?.didTouchRisksUILevelSectionLink(section.link)
                  })
        }
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

    @objc private func statusDataChanged() {
        reloadUI()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }

}

extension MyHealthController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}
