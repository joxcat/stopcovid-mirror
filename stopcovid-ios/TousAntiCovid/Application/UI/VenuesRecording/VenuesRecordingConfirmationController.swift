// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesRecordingConfirmationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2020 - for the TousAntiCovid project.
//

import UIKit
import Lottie

final class VenuesRecordingConfirmationController: CVTableViewController {

    private let venueType: String
    private let didFinish: () -> ()

    init(venueType: String, didFinish: @escaping () -> ()) {
        self.venueType = venueType
        self.didFinish = didFinish
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }

    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let animation: Animation = Animation.named(UIColor.isDarkMode ? "ERP-Waving" : "ERP-Waving-Dark")!
        let stateRow: CVRow = CVRow(animation: animation,
                                    xibName: .animationCell,
                                    theme: CVRow.Theme(topInset: 40.0))
        rows.append(stateRow)

        var confirmationTitle: String = "erp.confirmationMessage.\(venueType.lowercased()).title".localizedOrEmpty
        if confirmationTitle.isEmpty {
            confirmationTitle = "erp.confirmationMessage.default.title".localized
        }
        var confirmationMessage: String = "erp.confirmationMessage.\(venueType.lowercased()).message".localizedOrEmpty
        if confirmationMessage.isEmpty {
            confirmationMessage = "erp.confirmationMessage.default.message".localized
        }
        let textRow: CVRow = CVRow(title: confirmationTitle,
                                   subtitle: confirmationMessage,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 40.0,
                                                      bottomInset: 20.0,
                                                      textAlignment: .center,
                                                      titleFont: { Appearance.Controller.titleFont }))
        rows.append(textRow)
        return rows
    }

    private func initUI() {
        bottomButtonContainerController?.title = "venuesRecording.confirmationController.title".localized
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        bottomButtonContainerController?.navigationItem.setHidesBackButton(true, animated: false)
        bottomButtonContainerController?.updateButton(title: "common.ok".localized) { [weak self] in
            self?.didFinish()
        }

    }

}

extension VenuesRecordingConfirmationController: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadUI()
    }

}
