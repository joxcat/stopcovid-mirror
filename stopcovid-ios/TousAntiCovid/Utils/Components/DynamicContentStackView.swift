// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DynamicContentStackView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 28/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class DynamicContentStackView: UIStackView {

    var threshold: UIContentSizeCategory = .accessibilityMedium {
        didSet {
            changeInPreferredContentSize()
        }
    }
    var thresholdAxis: NSLayoutConstraint.Axis = .vertical {
        didSet {
            changeInPreferredContentSize()
        }
    }
    var thresholdAlignment: UIStackView.Alignment = .leading {
        didSet {
            changeInPreferredContentSize()
        }
    }
    var thresholdSpacing: CGFloat = 0.0 {
        didSet {
            changeInPreferredContentSize()
        }
    }
    
    var originalAxis: NSLayoutConstraint.Axis!
    private var originalAlignment: UIStackView.Alignment!
    private var originalSpacing: CGFloat!

    private var isLarge: Bool { UIApplication.shared.preferredContentSizeCategory >= threshold }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        originalAxis = axis
        originalAlignment = alignment
        originalSpacing = spacing
        changeInPreferredContentSize()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeInPreferredContentSize),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func changeInPreferredContentSize() {
        if isLarge {
            axis = thresholdAxis
            alignment = thresholdAlignment
            spacing = thresholdSpacing
        } else {
            axis = originalAxis
            alignment = originalAlignment
            spacing = thresholdSpacing
        }
    }
}
