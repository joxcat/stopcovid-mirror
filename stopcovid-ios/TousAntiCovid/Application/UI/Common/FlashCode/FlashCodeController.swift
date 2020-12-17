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

class FlashCodeController: UIViewController {

    @IBOutlet var explanationLabel: UILabel!
    @IBOutlet var scanView: QRScannerView!
    
    var deinitBlock: (() -> ())?
    
    private var isFirstLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        scanView.delegate = self
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
    
    func initUI() {
        fatalError("Must be overriden")
    }
    
    func restartScanning() {
        scanView.startScanning()
    }
    
    func processScannedQRCode(code: String?) {
       fatalError("Must be overriden")
    }

}

extension FlashCodeController: QRScannerViewDelegate {
    
    func qrScanningDidStop() {}
    func qrScanningDidFail() {}
    
    func qrScanningSucceededWithCode(_ str: String?) {
        processScannedQRCode(code: str)
    }
    
}
