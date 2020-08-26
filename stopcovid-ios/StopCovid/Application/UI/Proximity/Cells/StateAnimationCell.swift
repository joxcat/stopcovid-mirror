//
//  StateAnimationCell.swift
//  StopCovid
//
//  Created by Nicolas on 28/07/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
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
