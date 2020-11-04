// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ComponentHighlightButton.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class ComponentHighlightButton: UIButton {

    @IBOutlet var highlightingViews: [UIView] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonPressed), for: .touchDragInside)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpInside)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpOutside)
        addTarget(self, action: #selector(buttonReleased), for: .touchCancel)
        addTarget(self, action: #selector(buttonReleased), for: .touchDragOutside)
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        highlightingViews.forEach { $0.layer.removeAllAnimations() }
        highlightingViews.forEach { $0.alpha = 0.6 }
    }
    
    @IBAction func buttonReleased(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.highlightingViews.forEach { $0.alpha = 1.0 }
        }
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if bounds.contains(touch.location(in: self)) {
            return true
        } else {
            buttonReleased(self)
            return false
        }
    }

}
