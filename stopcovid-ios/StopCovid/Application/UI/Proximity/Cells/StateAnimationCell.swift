// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StateAnimationCell.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit
import Lottie

final class StateAnimationCell: CVTableViewCell {

    @IBOutlet var animationView: AnimationView?
    
    private let defaultAnimationSpeed: CGFloat = 1.0
    private let waveAnimationSpeed: CGFloat = 1.0
    
    private var isDarkMode: Bool {
        if #available(iOS 12.0, *) {
            return traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        animationView?.backgroundColor = .clear
    }
    
    func setOff(animated: Bool = true, completion: (() -> ())? = nil) {
        if animated {
            animationView?.animation = Animation.named(isDarkMode ? "OffToOn-Dark" : "OffToOn")!
            animationView?.currentProgress = 1.0
            animationView?.animationSpeed = defaultAnimationSpeed
            animationView?.loopMode = .playOnce
            animationView?.play(fromProgress: 1.0, toProgress: 0.0, loopMode: .playOnce) { _ in
                completion?()
            }
        } else {
            animationView?.animation = Animation.named(isDarkMode ? "OffToOn-Dark" : "OffToOn")!
        }
    }
    
    func setOn(animated: Bool = true, completion: (() -> ())? = nil) {
        if animated {
            animationView?.animation = Animation.named(isDarkMode ? "OffToOn-Dark" : "OffToOn")!
            animationView?.animationSpeed = defaultAnimationSpeed
            animationView?.loopMode = .playOnce
            animationView?.play { [weak self] completed in
                if completed {
                    self?.setOnWaving()
                }
                completion?()
            }
        } else {
            setOnWaving()
            completion?()
        }
    }
    
    func setLoading() {
        animationView?.animation = Animation.named(isDarkMode ? "LoadingBle-Dark" : "LoadingBle")!
        animationView?.animationSpeed = waveAnimationSpeed
        animationView?.loopMode = .loop
        animationView?.play()
    }
    
    func continuePlayingIfNeeded() {
        guard animationView?.currentProgress ?? 0.0 > 0.0 && animationView?.currentProgress ?? 0.0 < 1.0 else { return }
        animationView?.play()
    }
    
    private func setOnWaving() {
        animationView?.animation = Animation.named(isDarkMode ? "OnWaving-Dark" : "OnWaving")!
        animationView?.animationSpeed = waveAnimationSpeed
        animationView?.loopMode = .loop
        animationView?.play()
    }
    
}
