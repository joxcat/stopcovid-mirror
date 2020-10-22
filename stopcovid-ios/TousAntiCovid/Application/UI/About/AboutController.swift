// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AboutController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class AboutController: CVTableViewController {
    
    private var deinitBlock: (() -> ())?
    
    init(deinitBlock: @escaping () -> ()) {
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
        deinitBlock?()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let appLogoRow: CVRow = CVRow(image: Asset.Images.logo.image,
                                      xibName: .onboardingImageCell,
                                      theme: CVRow.Theme(topInset: 20.0, imageRatio: Appearance.Cell.Image.defaultRatio))
        rows.append(appLogoRow)
        let appVersionRow: CVRow = CVRow(title: "app.name".localized,
                                         subtitle: String(format: "aboutController.appVersion".localized, UIApplication.shared.marketingVersion, UIApplication.shared.buildNumber),
                                         xibName: .textCell,
                                         theme: CVRow.Theme(topInset: 16.0, separatorLeftInset: nil))
        rows.append(appVersionRow)
        let textRow: CVRow = CVRow(title: "aboutController.mainMessage.title".localized,
                                   subtitle: "aboutController.mainMessage.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 40.0, bottomInset: 20.0, textAlignment: .natural, separatorLeftInset: nil))
        rows.append(textRow)
        let internetRow: CVRow = CVRow(title: "aboutController.webpage".localized,
                                   xibName: .standardCell,
                                   theme: CVRow.Theme(topInset: 15.0,
                                                      bottomInset: 15.0,
                                                      textAlignment: .natural,
                                                      titleFont: { Appearance.Cell.Text.standardFont },
                                                      titleColor: Asset.Colors.tint.color,
                                                      separatorLeftInset: Appearance.Cell.leftMargin),
                                   selectionAction: {
            URL(string: "aboutController.webpageUrl".localized)?.openInSafari()
        })
        rows.append(internetRow)
        let faqRow: CVRow = CVRow(title: "aboutController.faq".localized,
                                   xibName: .standardCell,
                                   theme: CVRow.Theme(topInset: 15.0,
                                                      bottomInset: 15.0,
                                                      textAlignment: .natural,
                                                      titleFont: { Appearance.Cell.Text.standardFont },
                                                      titleColor: Asset.Colors.tint.color,
                                                      separatorLeftInset: Appearance.Cell.leftMargin),
                                   selectionAction: {
            URL(string: "aboutController.faqUrl".localized)?.openInSafari()
        })
        rows.append(faqRow)
        let opinionRow: CVRow = CVRow(title: "aboutController.opinion".localized,
                                   xibName: .standardCell,
                                   theme: CVRow.Theme(topInset: 15.0,
                                                      bottomInset: 15.0,
                                                      textAlignment: .natural,
                                                      titleFont: { Appearance.Cell.Text.standardFont },
                                                      titleColor: Asset.Colors.tint.color,
                                                      separatorLeftInset: 0.0),
                                   selectionAction: {
            URL(string: "aboutController.opinionUrl".localized)?.openInSafari()
        })
        rows.append(opinionRow)
        rows.append(.empty)
        return rows
    }
    
    private func updateTitle() {
        title = "aboutController.title".localized
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension AboutController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

