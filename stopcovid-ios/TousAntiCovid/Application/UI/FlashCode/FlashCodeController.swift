// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  FlashCodeController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class FlashCodeController: UIViewController {

    @IBOutlet private var scanView: QRScannerView!
    @IBOutlet private var explanationLabel: UILabel!
    
    private var isFirstLoad: Bool = true
    private var didFlash: ((_ code: String?) -> ())?
    private var deinitBlock: (() -> ())?
    
    class func controller(didFlash: @escaping (_ code: String?) -> (), deinitBlock: @escaping () -> ()) -> UIViewController {
        let flashCodeController: FlashCodeController = StoryboardScene.FlashCode.flashCodeController.instantiate()
        flashCodeController.didFlash = didFlash
        flashCodeController.deinitBlock = deinitBlock
        return flashCodeController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "sickController.button.flash".localized
        scanView.delegate = self
        explanationLabel.text = "scanCodeController.explanation".localized
        explanationLabel.font = Appearance.Cell.Text.standardFont
        explanationLabel.adjustsFontForContentSizeCategory = true
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
        } else {
            scanView.startScanning()
        }
    }
    
    deinit {
        deinitBlock?()
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }

}

extension FlashCodeController: QRScannerViewDelegate {
    
    func qrScanningDidStop() {}
    func qrScanningDidFail() {}
    
    func qrScanningSucceededWithCode(_ str: String?) {
        if str?.isUuidCode == true {
            didFlash?(str)
        } else {
            showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                      message: "enterCodeController.alert.invalidCode.message".localized,
                      okTitle: "common.ok".localized, handler: {
                        self.scanView.startScanning()
            })
        }
    }
    
}
