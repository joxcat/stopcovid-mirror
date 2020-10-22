// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StateAnimationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import Lottie

final class StateAnimationCell: CVTableViewCell {
    
    @IBOutlet var animationView: AnimationView?
    
    private let defaultAnimationSpeed: CGFloat = 1.0
    private let waveAnimationSpeed: CGFloat = 1.0
    private let offToOnAnimation: Animation = Animation.named(UIColor.isDarkMode ? "OffToOn-Dark" : "OffToOn")!
    private let onWavingAnimation: Animation = Animation.named(UIColor.isDarkMode ? "OnWaving-Dark" : "OnWaving")!
    private var lastLoadedAnimationName: String?
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        animationView?.backgroundColor = .clear
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityElements = []
        accessibilityElementsHidden = true
    }
    
    func setOff(animated: Bool = true, completion: (() -> ())? = nil) {
        guard lastLoadedAnimationName != "setOff" else {
            completion?()
            return
        }
        lastLoadedAnimationName = "setOff"
        if animated {
            animationView?.animation = offToOnAnimation
            animationView?.currentProgress = 1.0
            animationView?.animationSpeed = defaultAnimationSpeed
            animationView?.loopMode = .playOnce
            animationView?.play(fromProgress: 1.0, toProgress: 0.0, loopMode: .playOnce) { _ in
                completion?()
            }
        } else {
            animationView?.animation = offToOnAnimation
        }
    }
    
    func setOn(animated: Bool = true, completion: (() -> ())? = nil) {
        if animated {
            guard lastLoadedAnimationName != "setOn" else {
                completion?()
                return
            }
            lastLoadedAnimationName = "setOn"
            animationView?.animation = offToOnAnimation
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
    
    func continuePlayingIfNeeded() {
        guard animationView?.currentProgress ?? 0.0 > 0.0 && animationView?.currentProgress ?? 0.0 < 1.0 else { return }
        animationView?.play()
    }
    
    private func setOnWaving() {
        guard lastLoadedAnimationName != "setOnWaving" else {
            animationView?.play()
            return
        }
        lastLoadedAnimationName = "setOnWaving"
        animationView?.animation = onWavingAnimation
        animationView?.animationSpeed = waveAnimationSpeed
        animationView?.loopMode = .loop
        animationView?.play()
    }
    
}
