// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesRecordingOnboardingController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class VenuesRecordingOnboardingController: CVTableViewController {

    private let didContinue: () -> ()
    private let deinitBlock: () -> ()

    init(didContinue: @escaping () -> (), deinitBlock: @escaping () -> ()) {
        self.didContinue = didContinue
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomButtonContainerController?.unlockButtons()
    }

    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock()
    }

    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.venuesRecording.image,
                                      xibName: .onboardingImageCell,
                                      theme: CVRow.Theme(topInset: 40.0,
                                                         imageRatio: Appearance.Cell.Image.defaultRatio))
        rows.append(imageRow)
        let textRow: CVRow = CVRow(title: "venuesRecording.onboardingController.mainMessage.title".localized,
                                   subtitle: "venuesRecording.onboardingController.mainMessage.message".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 40.0,
                                                      bottomInset: 20.0,
                                                      textAlignment: .center))
        rows.append(textRow)
        return rows
    }

    private func initUI() {
        bottomButtonContainerController?.title = "venuesRecording.onboardingController.title".localized
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        bottomButtonContainerController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))

        bottomButtonContainerController?.updateButton(title: "venuesRecording.onboardingController.button.participate".localized) { [weak self] in
            self?.didContinue()
        }

    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension VenuesRecordingOnboardingController: LocalizationsChangesObserver {

    func localizationsChanged() {
        reloadUI()
    }

}
