// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesPrivateEventController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/11/2020 - for the TousAntiCovid project.
//

import UIKit
import Lottie
import PKHUD

final class VenuesPrivateEventController: CVTableViewController {

    private let deinitBlock: () -> ()

    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
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
        deinitBlock()
    }

    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let qrCodeRow: CVRow = CVRow(title: VenuesManager.shared.currentQrCodeString,
                                     image: VenuesManager.shared.currentQrCodeImage,
                                     xibName: .privateEventQRCodeCell,
                                     theme: CVRow.Theme(topInset: 20.0,
                                                        bottomInset: 20.0,
                                                        leftInset: 0.0,
                                                        rightInset: 0.0,
                                                        textAlignment: .center,
                                                        titleFont: { Appearance.Cell.Text.accessoryFont },
                                                        titleColor: Appearance.Cell.Text.titleColor.withAlphaComponent(0.5)))
        rows.append(qrCodeRow)
        let textRow: CVRow = CVRow(title: "venuesPrivateEventController.mainMessage.title".localized,
                                   subtitle: "venuesPrivateEventController.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 20.0,
                                                      bottomInset: 20.0,
                                                      textAlignment: .center))
        rows.append(textRow)
        let shareRow: CVRow = CVRow(title: "venuesPrivateEventController.button.sharedCode".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 30.0, bottomInset: 0.0, buttonStyle: .primary),
                                        selectionAction: { [weak self] in
                                            self?.didTouchShareCode()
        })
        rows.append(shareRow)
        return rows
    }

    private func initUI() {
        title = "venuesPrivateEventController.title".localized
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }

    private func didTouchShareCode() {
        let activityItems: [Any?] = ["\("venuesPrivateEventController.sharing.text".localized)\n\(VenuesManager.shared.currentQrCodeString ?? "")", VenuesManager.shared.currentQrCodeImage]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension VenuesPrivateEventController: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadUI()
    }

}
