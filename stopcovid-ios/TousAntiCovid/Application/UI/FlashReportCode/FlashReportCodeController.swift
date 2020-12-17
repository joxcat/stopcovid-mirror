// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashReportCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class FlashReportCodeController: FlashCodeController {
    
    private var didFlash: ((_ code: String?) -> ())?
    
    class func controller(didFlash: @escaping (_ code: String?) -> (), deinitBlock: (() -> ())? = nil) -> UIViewController {
        let flashCodeController: FlashReportCodeController = StoryboardScene.FlashReportCode.flashCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        return flashCodeController
    }
    
    override func initUI() {
        title = "sickController.button.flash".localized
        explanationLabel.text = "scanCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }

    override func processScannedQRCode(code: String?) {
        if code?.isUuidCode == true {
            didFlash?(code)
        } else {
            showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                      message: "enterCodeController.alert.invalidCode.message".localized,
                      okTitle: "common.ok".localized, handler: {
                        self.restartScanning()
            })
        }
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}
