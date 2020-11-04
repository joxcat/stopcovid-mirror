// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  QRCodeCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import UIKit

final class QRCodeCell: CVTableViewCell {

    @IBOutlet private var topRightButton: UIButton!
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupAccessibility()
    }
    
    override func capture() -> UIImage? {
        topRightButton.isHidden = true
        let image: UIImage? = containerView.screenshot()
        topRightButton.isHidden = false
        return image
    }
    
    private func setupUI() {
        selectionStyle = .none
        accessoryType = .none
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        topRightButton.tintColor = Appearance.tintColor
    }
    
    private func setupAccessibility() {
        accessibilityElements = [cvTitleLabel, topRightButton].compactMap { $0 }
        topRightButton.accessibilityLabel = "attestationsController.menu.share".localized
    }
    
    @IBAction private func topRightButtonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard currentAssociatedRow?.selectionAction != nil else { return }
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            contentView.layer.removeAllAnimations()
            contentView.alpha = 0.6
        } else {
            UIView.animate(withDuration: 0.3) {
                self.contentView.alpha = 1.0
            }
        }
    }
    
}
