// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import AVFoundation

final class CaptchaViewController: CVTableViewController {
    
    private weak var textField: UITextField?
    private var captcha: Captcha
    private var answer: String?
    private var player: AVAudioPlayer?
    private var audioCellIndexPath: IndexPath?
    
    private let didEnterCaptcha: (_ id: String, _ answer: String) -> ()
    private let deinitBlock: () -> ()
    
    init(captcha: Captcha, didEnterCaptcha: @escaping (_ id: String, _ answer: String) -> (), deinitBlock: @escaping () -> ()) {
        self.captcha = captcha
        self.didEnterCaptcha = didEnterCaptcha
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the above init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "captchaController.title".localized
        initUI()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        if !captcha.isImage {
            loadAudio()
        }
        reloadUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField?.resignFirstResponder()
    }
    
    deinit {
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        deinitBlock()
    }
    
    override func createRows() -> [CVRow] {
        var rows: [CVRow] = []
        let textRow: CVRow = CVRow(title: captcha.isImage ? "captchaController.mainMessage.image.title".localized : "captchaController.mainMessage.audio.title".localized,
                                   subtitle: captcha.isImage ? "captchaController.mainMessage.image.subtitle".localized : "captchaController.mainMessage.audio.subtitle".localized,
                                   xibName: .textCell,
                                   theme: CVRow.Theme(topInset: 30.0, bottomInset: 30.0))
        rows.append(textRow)
        
        let imageWidth: CGFloat = UIScreen.main.bounds.width - 2 * Appearance.Cell.leftMargin
        let imageHeight: CGFloat = imageWidth / 3.0
        let imageTopMargin: CGFloat = 10.0
        let playButtonHeight: CGFloat = 62.0
        let playButtonTopMargin: CGFloat = (imageHeight + 2.0 * imageTopMargin - playButtonHeight) / 2.0
        if captcha.isImage {
            let imageRow: CVRow = CVRow(image: captcha.image,
                                        xibName: .standardCell,
                                        theme: CVRow.Theme(topInset: imageTopMargin,
                                                           bottomInset: imageTopMargin,
                                                           imageSize: CGSize(width: imageWidth, height: imageHeight)),
                                        willDisplay: { cell in
                cell.cvImageView?.isAccessibilityElement = true
                cell.cvImageView?.accessibilityTraits = .image
                cell.cvImageView?.accessibilityHint = "accessibility.hint.captcha.image".localized
            })
            rows.append(imageRow)
        } else {
            let audioRow: CVRow = CVRow(image: player?.isPlaying == true ? Asset.Images.pause.image : Asset.Images.play.image,
                                        xibName: .audioCell,
                                        theme: CVRow.Theme(topInset: playButtonTopMargin,
                                                           bottomInset: playButtonTopMargin,
                                                           imageSize: CGSize(width: playButtonHeight, height: playButtonHeight)),
                                        selectionAction: { [weak self] in
                guard let self = self else { return }
                if self.player?.isPlaying == true {
                    self.stopPlayingCaptcha()
                } else {
                    self.startPlayingCaptcha()
                }
            }, willDisplay: { [weak self] cell in
                guard let self = self else { return }
                (cell as? AudioCell)?.button.accessibilityHint = self.player?.isPlaying == true ? "accessibility.hint.captcha.audio.button.pause".localized : "accessibility.hint.captcha.audio.button.play".localized
                (cell as? AudioCell)?.button.accessibilityTraits = .startsMediaSession
            })
            audioCellIndexPath = IndexPath(row: rows.count, section: 0)
            rows.append(audioRow)
        }
        let textFieldRow: CVRow = CVRow(placeholder: captcha.isImage ? "captchaController.textField.image.placeholder".localized : "captchaController.textField.audio.placeholder".localized,
                                        xibName: .textFieldCell,
                                        theme: CVRow.Theme(topInset: 20.0,
                                                           bottomInset: 20.0,
                                                           placeholderColor: .lightGray,
                                                           separatorLeftInset: 0.0),
                                        textFieldKeyboardType: .default,
                                        textFieldReturnKeyType: .done,
                                        willDisplay: { [weak self] cell in
                                            self?.textField = (cell as? TextFieldCell)?.cvTextField
                                            
        }, valueChanged: { [weak self] value in
            guard let answer = value as? String else { return }
            self?.answer = answer
        }, didValidateValue: { [weak self] value, _ in
            guard let answer = value as? String else { return }
            self?.answer = answer
            self?.didTouchConfirm()
        })
        rows.append(textFieldRow)
        let generateRow: CVRow = CVRow(title: captcha.isImage ? "captchaController.generate.image".localized : "captchaController.generate.sound".localized,
                                       image: Asset.Images.replay.image,
                                       xibName: .standardCell,
                                       theme: CVRow.Theme(topInset: 15.0,
                                                          bottomInset: 15.0,
                                                          textAlignment: .natural,
                                                          titleFont: { Appearance.Cell.Text.standardFont },
                                                          titleColor: Asset.Colors.tint.color,
                                                          imageTintColor: Appearance.Cell.Image.tintColor,
                                                          imageSize: Appearance.Cell.Image.size,
                                                          imageRatio: nil,
                                                          separatorLeftInset: Appearance.Cell.leftMargin),
                                       selectionAction: { [weak self] in
            self?.reloadCaptcha()
        }, willDisplay: { cell in
            cell.cvTitleLabel?.accessibilityTraits = .button
            cell.accessoryType = .none
        })
        rows.append(generateRow)
        let switchTypeRow: CVRow = CVRow(title: captcha.isImage ? "captchaController.switchToAudio".localized : "captchaController.switchToImage".localized,
                                         image: captcha.isImage ? Asset.Images.audio.image : Asset.Images.visual.image,
                                         xibName: .standardCell,
                                         theme: CVRow.Theme(topInset: 15.0,
                                                            bottomInset: 15.0,
                                                            textAlignment: .natural,
                                                            titleFont: { Appearance.Cell.Text.standardFont },
                                                            titleColor: Asset.Colors.tint.color,
                                                            imageTintColor: Appearance.Cell.Image.tintColor,
                                                            imageSize: Appearance.Cell.Image.size,
                                                            imageRatio: nil,
                                                            separatorLeftInset: 0.0),
                                         selectionAction: { [weak self] in
            guard let self = self else { return }
            if self.captcha.isImage {
                self.reloadAudioCaptcha()
            } else {
                self.reloadImageCaptcha()
            }
        }, willDisplay: { cell in
            cell.cvTitleLabel?.accessibilityTraits = .button
            cell.accessoryType = .none
        })
        rows.append(switchTypeRow)
        rows.append(.empty)
        return rows
    }
    
    private func initUI() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.backgroundColor
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        navigationController?.navigationBar.titleTextAttributes = [.font: Appearance.NavigationBar.titleFont]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "captchaController.button.title".localized, style: .plain, target: self, action: #selector(didTouchConfirm))
    }
    
    private func loadAudio() {
        guard let data = captcha.audio else { return }
        player = try! AVAudioPlayer(data: data)
        player?.delegate = self
        player?.prepareToPlay()
    }
    
    private func startPlayingCaptcha() {
        player?.play()
        rows = createRows()
        tableView.reloadRows(at: [audioCellIndexPath].compactMap { $0 }, with: .automatic)
    }
    
    private func stopPlayingCaptcha() {
        player?.pause()
        player?.currentTime = 0.0
        rows = createRows()
        tableView.reloadRows(at: [audioCellIndexPath].compactMap { $0 }, with: .automatic)
    }
    
    @objc private func didTouchConfirm() {
        if let answer = answer, !answer.isEmpty {
            tableView.endEditing(true)
            validateCaptcha()
        } else {
            showAlert(title: "captchaController.alert.noAnswer.title".localized,
                      message: "captchaController.alert.noAnswer.message".localized,
                      okTitle: "common.ok".localized, handler:  { [weak self] in
                        self?.textField?.becomeFirstResponder()
                      })
        }
    }
    
    private func reloadCaptcha() {
        if captcha.isImage {
            reloadImageCaptcha()
        } else {
            reloadAudioCaptcha()
        }
    }
    
    private func reloadImageCaptcha() {
        stopPlayingCaptcha()
        HUD.show(.progress)
        CaptchaManager.shared.generateCaptchaImage { result in
            HUD.hide()
            switch result {
            case let .success(captcha):
                self.captcha = captcha
                self.reloadUI(animated: true)
            case let .failure(error):
                self.showAlert(title: "common.error".localized, message: error.localizedDescription, okTitle: "common.ok".localized)
            }
        }
    }
    
    private func reloadAudioCaptcha() {
        stopPlayingCaptcha()
        HUD.show(.progress)
        CaptchaManager.shared.generateCaptchaAudio { result in
            HUD.hide()
            switch result {
            case let .success(captcha):
                self.captcha = captcha
                self.loadAudio()
                self.reloadUI(animated: true)
            case let .failure(error):
                self.showAlert(title: "common.error".localized, message: error.localizedDescription, okTitle: "common.ok".localized)
            }
        }
    }
    
    private func validateCaptcha() {
        didEnterCaptcha(captcha.id, answer ?? "")
    }
    
    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension CaptchaViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayingCaptcha()
    }
    
}
