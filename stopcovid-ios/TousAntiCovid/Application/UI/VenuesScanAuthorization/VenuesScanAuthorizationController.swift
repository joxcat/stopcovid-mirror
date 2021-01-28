// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesScanAuthorizationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 13/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class VenuesScanAuthorizationController: CVTableViewController {

    private let didAnswer: (_ granted: Bool) -> ()

    init(didAnswer: @escaping (_ granted: Bool) -> ()) {
        self.didAnswer = didAnswer
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
        LocalizationsManager.shared.addObserver(self)
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func updateTitle() {
        title = "confirmVenueQrCodeController.title".localized
    }

    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.venuesRecording.image,
                                      xibName: .onboardingImageCell,
                                      theme: CVRow.Theme(topInset: 40.0,
                                                         imageRatio: Appearance.Cell.Image.defaultRatio))
        rows.append(imageRow)
        let explanationRow: CVRow = CVRow(title: "confirmVenueQrCodeController.explanation.title".localized,
                                          xibName: .textCell,
                                          theme: CVRow.Theme(topInset: 40.0,
                                                             bottomInset: 10.0,
                                                             textAlignment: .center))
        rows.append(explanationRow)
        let questionRow: CVRow = CVRow(title: "confirmVenueQrCodeController.explanation.subtitle".localized,
                                       xibName: .textCell,
                                       theme: CVRow.Theme(topInset: 10.0,
                                                          bottomInset: 20.0,
                                                          textAlignment: .center))
        rows.append(questionRow)
        let acceptRow: CVRow = CVRow(title: "confirmVenueQrCodeController.confirm".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 20.0, bottomInset: 10.0, buttonStyle: .primary),
                                        selectionAction: { [weak self] in
                                            self?.didAnswer(true)
        })
        rows.append(acceptRow)
        let refuseRow: CVRow = CVRow(title: "common.cancel".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 10.0,
                                                           bottomInset: 0.0,
                                                           buttonStyle: .destructive),
                                        selectionAction: { [weak self] in
                                            self?.didAnswer(false)
                                        })
        rows.append(refuseRow)
        return rows
    }

}

extension VenuesScanAuthorizationController: LocalizationsChangesObserver {

    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }

}
