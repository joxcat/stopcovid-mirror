// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVButton.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class CVButton: UIButton {
    
    enum Style {
        case primary
        case secondary
        case tertiary
        case quaternary
        case destructive
    }
    
    var buttonStyle: Style = .primary { didSet { initUI() } }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initUI()
    }
    
    private func initUI() {
        contentEdgeInsets = Appearance.Button.contentEdgeInsets
        setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        titleLabel?.font = Appearance.Button.font
        titleLabel?.numberOfLines = 0
        titleLabel?.adjustsFontForContentSizeCategory = true
        adjustsImageSizeForAccessibilityContentSizeCategory = true
        layer.cornerRadius = Appearance.Button.cornerRadius
        updateButtonStyle()
    }
    
    private func updateButtonStyle() {
        switch buttonStyle {
        case .primary:
            backgroundColor = Appearance.Button.Primary.backgroundColor
            setTitleColor(Appearance.Button.Primary.titleColor, for: .normal)
        case .secondary:
            backgroundColor = Appearance.Button.Secondary.backgroundColor
            setTitleColor(Appearance.Button.Secondary.titleColor, for: .normal)
        case .tertiary:
            backgroundColor = Appearance.Button.Tertiary.backgroundColor
            setTitleColor(Appearance.Button.Tertiary.titleColor, for: .normal)
        case .quaternary:
            backgroundColor = Appearance.Button.Quaternary.backgroundColor
            setTitleColor(Appearance.Button.Quaternary.titleColor, for: .normal)
        case .destructive:
            backgroundColor = Appearance.Button.Destructive.backgroundColor
            setTitleColor(Appearance.Button.Destructive.titleColor, for: .normal)
        }
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let ret = super.beginTracking(touch, with: event)
        if ret {
            let generator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        return ret
    }
    
}
