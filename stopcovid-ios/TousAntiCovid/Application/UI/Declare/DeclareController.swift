// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeclareController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/09/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK
import MessageUI

final class DeclareController: CVTableViewController {
    
    let didTouchFlash: () -> ()
    let didTouchTap: () -> ()
    let didTouchShowVideo: (_ url: URL) -> ()
    let deinitBlock: () -> ()
    
    init(didTouchFlash: @escaping () -> (), didTouchTap: @escaping () -> (), didTouchShowVideo: @escaping (_ url: URL) -> (), deinitBlock: @escaping () -> ()) {
        self.didTouchFlash = didTouchFlash
        self.didTouchTap = didTouchTap
        self.didTouchShowVideo = didTouchShowVideo
        self.deinitBlock = deinitBlock
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
        addObservers()
    }
    
    deinit {
        removeObservers()
        deinitBlock()
    }
    
    private func updateTitle() {
        title = "declareController.title".localized
    }
    
    override func createRows() -> [CVRow] {
        let imageRow: CVRow = CVRow(image: Asset.Images.declare.image,
                                    xibName: .imageCell,
                                    theme: CVRow.Theme(imageRatio: 375.0 / 248.0))
        return [imageRow] + commonRows()
    }
    
    private func commonRows() -> [CVRow] {
        var rows: [CVRow] = []
        if RBManager.shared.isRegistered {
            let textRow: CVRow = CVRow(title: "sickController.message.testedPositive.title".localized,
                                       subtitle: "sickController.message.testedPositive.subtitle".localized,
                                       xibName: .cardTextCell,
                                       theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                          topInset: 0.0,
                                                          bottomInset: 0.0))
            rows.append(textRow)
            let codeNotReceivedButtonRow: CVRow = CVRow(title: "declareController.codeNotReceived.buttonTitle".localized,
                                                        xibName: .buttonCell,
                                                        theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0, buttonStyle: .quaternary),
                                                        selectionAction: { [weak self] in
                                                            self?.didTouchCodeNotReceivedButton()
                                                        })
            rows.append(codeNotReceivedButtonRow)
            let flashButtonRow: CVRow = CVRow(title: "sickController.button.flash".localized,
                                              xibName: .buttonCell,
                                              theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0),
                                              selectionAction: { [weak self] in
                                                self?.didTouchFlashButton()
            }, willDisplay: { cell in
                (cell as? ButtonCell)?.button.accessibilityHint = "accessibility.hint.sick.qrCode.enterCodeOnNextButton".localized
            })
            rows.append(flashButtonRow)
            let tapButtonRow: CVRow = CVRow(title: "sickController.button.tap".localized,
                                            xibName: .buttonCell,
                                            theme: CVRow.Theme(topInset: 20.0, bottomInset: 0.0, buttonStyle: .secondary),
                                            selectionAction: { [weak self] in
                                                self?.didTouchTapButton()
            })
            rows.append(tapButtonRow)
        } else {
            let textRow: CVRow = CVRow(title: "declareController.notRegistered.mainMessage.title".localized,
                                       subtitle: "declareController.notRegistered.mainMessage.subtitle".localized,
                                       xibName: .textCell,
                                       theme: CVRow.Theme(topInset: 20.0))
            rows.append(textRow)
        }
        return rows
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
    
    @objc private func didTouchFlashButton() {
        CameraAuthorizationManager.requestAuthorization { granted, isFirstTimeRequest in
            if granted {
                self.didTouchFlash()
            } else if !isFirstTimeRequest {
                self.showAlert(title: "scanCodeController.camera.authorizationNeeded.title".localized,
                               message: "scanCodeController.camera.authorizationNeeded.message".localized,
                               okTitle: "common.settings".localized,
                               cancelTitle: "common.cancel".localized, handler:  {
                                UIApplication.shared.openSettings()
                               })
            }
        }
    }
    
    @objc private func didTouchTapButton() {
        didTouchTap()
    }
    
    @objc private func didTouchCodeNotReceivedButton() {
        let alertController: UIAlertController = UIAlertController(title: "declareController.codeNotReceived.alert.title".localized,
                                                                   message: "declareController.codeNotReceived.alert.message".localized,
                                                                   preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        alertController.addAction(UIAlertAction(title: "declareController.codeNotReceived.alert.showVideo".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchShowVideo(URL(string: "declareController.codeNotReceived.alert.video.url".localized)!)
        }))
        alertController.addAction(UIAlertAction(title: "declareController.codeNotReceived.alert.contactUs".localized, style: .default, handler: { _ in
            URL(string: "contactUs.url".localized)?.openInSafari()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func statusDataChanged() {
        reloadUI()
    }

}

extension DeclareController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}

extension DeclareController: MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
