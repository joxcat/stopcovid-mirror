// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationFullScreenViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//
import UIKit

final class AttestationFullScreenViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var label: UILabel!
    @IBOutlet private var closeButton: UIButton!
    
    private var qrCode: UIImage!
    private var text: String!
    private var lastBrightness: CGFloat = 0.0
    private var isFirstLoad: Bool = true
    
    static func controller(qrCode: UIImage, text: String) -> UIViewController {
        let fullscreenController: AttestationFullScreenViewController = StoryboardScene.Attestation.attestationFullScreenViewController.instantiate()
        fullscreenController.qrCode = qrCode
        fullscreenController.text = text
        return fullscreenController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        addObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            updateBrightnessForQRCodeReadability()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        putBrightnessBackToOriginalValue()
    }
    
    deinit {
        removeObservers()
    }
    
    private func setupUI() {
        imageView.image = qrCode
        label.text = text
        closeButton.setTitle("common.close".localized, for: .normal)
        label.font = .regular(size: 20.0)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateBrightnessForQRCodeReadability() {
        lastBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = CGFloat(1.0)
    }
    
    private func putBrightnessBackToOriginalValue() {
        UIScreen.main.brightness = lastBrightness
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc private func appDidBecomeActive() {
        updateBrightnessForQRCodeReadability()
    }
    
}
