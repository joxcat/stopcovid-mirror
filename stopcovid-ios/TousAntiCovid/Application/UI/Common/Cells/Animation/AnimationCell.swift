// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AnimationCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/11/2020 - for the TousAntiCovid project.
//

import UIKit
import Lottie

final class AnimationCell: CVTableViewCell {

    @IBOutlet var animationView: AnimationView?

    private let defaultAnimationSpeed: CGFloat = 1.0
    private let waveAnimationSpeed: CGFloat = 1.0

    override func setup(with row: CVRow) {
        super.setup(with: row)
        animationView?.backgroundColor = .clear
        setupAccessibility()
        setOnWaving(animation: row.animation)
    }

    private func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityElements = []
        accessibilityElementsHidden = true
    }

    private func setOnWaving(animation: Animation?) {
        guard animationView?.animation == nil else { return }
        animationView?.animation = animation
        animationView?.animationSpeed = waveAnimationSpeed
        animationView?.loopMode = .loop
        animationView?.play()
    }

}
