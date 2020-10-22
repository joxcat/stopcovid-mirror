// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AppMaintenanceController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2020 - for the TousAntiCovid project.
//


import UIKit
import PKHUD

final class AppMaintenanceController: CVTableViewController, MaintenanceController {

    var maintenanceInfo: MaintenanceInfo {
        didSet {
            if isViewLoaded {
                reloadUI()
            }
        }
    }
    private let didTouchAbout: () -> ()
    
    init(maintenanceInfo: MaintenanceInfo, didTouchAbout: @escaping () -> ()) {
        self.maintenanceInfo = maintenanceInfo
        self.didTouchAbout = didTouchAbout
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must use the standard init() method.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "app.name".localized
        initUI()
        reloadUI()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let imageRow: CVRow = CVRow(image: Asset.Images.maintenance.image,
                                    xibName: .onboardingImageCell,
                                    theme: CVRow.Theme(topInset: 40.0,
                                                       imageRatio: Appearance.Cell.Image.defaultRatio))
        rows.append(imageRow)
        let message: String = maintenanceInfo.localizedMessage ?? ""
        let messageComponents: [String] = message.components(separatedBy: "\n")
        let title: String = messageComponents[0]
        let subtitle: String = message.replacingOccurrences(of: "\(title)\n", with: "")
        let textRow: CVRow = CVRow(title: title,
                                   subtitle: subtitle,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 40.0))
        rows.append(textRow)
        
        if let buttonTitle = maintenanceInfo.localizedButtonTitle, let buttonUrl = maintenanceInfo.localizedButtonUrl, maintenanceInfo.mode == .upgrade {
            let buttonRow: CVRow = CVRow(title: buttonTitle,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 40.0),
                                        selectionAction: {
                URL(string: buttonUrl)?.openInSafari()
            })
            rows.append(buttonRow)
        } else {
            let retryRow: CVRow = CVRow(title: "common.tryAgain".localized,
                                        xibName: .buttonCell,
                                        theme: CVRow.Theme(topInset: 40.0),
                                        selectionAction: { [weak self] in
                                            self?.didTouchButton()
            })
            rows.append(retryRow)
        }
        return rows
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "common.about".localized, style: .plain, target: self, action: #selector(didTouchAboutButton))
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
    }
    
    @objc private func didTouchAboutButton() {
        didTouchAbout()
    }
    
    @objc private func didTouchButton() {
        HUD.show(.progress)
        MaintenanceManager.shared.checkMaintenanceState {
            HUD.hide()
        }
    }

}
