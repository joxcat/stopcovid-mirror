// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashVenueCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class FlashVenueCodeController: FlashCodeController {
    
    private var didFlash: ((_ code: String?) -> Bool)?
    
    class func controller(didFlash: @escaping (_ code: String?) -> Bool, deinitBlock: (() -> ())? = nil) -> FlashVenueCodeController {
        let flashCodeController: FlashVenueCodeController = StoryboardScene.FlashVenueCode.flashCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        return flashCodeController
    }
    
    override func initUI() {
        title = "venueFlashCodeController.title".localized
        explanationLabel.text = "venueFlashCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        }
        #if targetEnvironment(simulator)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Flash", style: .plain, target: self, action: #selector(didTouchFlashButton))
        #endif
    }

    override func processScannedQRCode(code: String?) {
        if didFlash?(code) == false {
            showErrorAlert()
        }
    }
    
    private func showErrorAlert() {
        showAlert(title: "venueFlashCodeController.alert.invalidCode.title".localized,
                  message: "venueFlashCodeController.alert.invalidCode.message".localized,
                  okTitle: "common.ok".localized, handler: {
                    self.restartScanning()
                  })
    }
    
    #if targetEnvironment(simulator)
    @objc private func didTouchFlashButton() {
        scanView.stopScanning()
        let values: (uuid: String, venueType: String) = [("491ab3ae-ad35-4301-8dd9-414ecf210713", "L"), ("491ab3ae-ad35-4301-8dd9-414ecf210714", "N")].randomElement()!
        if didFlash?("https://tac.gouv.fr/0/\(values.uuid)/\(values.venueType)/4/200/") == false {
            showErrorAlert()
        }
    }
    #endif
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}
