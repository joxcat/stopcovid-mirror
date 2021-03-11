// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ParagraphCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class ParagraphCell: CVTableViewCell {
    
    @IBOutlet private var button: UIButton!
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
    }
    
    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        selectionStyle = .none
        accessoryType = .none
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.contentHorizontalAlignment = .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
    }
    
    private func setupContent(row: CVRow) {
        if #available(iOS 13.0, *) {
            let imageAttachment: NSTextAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "arrow.up.right.square.fill")?.withRenderingMode(.alwaysTemplate)
            let fullString: NSMutableAttributedString = NSMutableAttributedString(string: "\(row.buttonTitle ?? "") ")
            fullString.append(NSAttributedString(attachment: imageAttachment))
            button.setAttributedTitle(fullString, for: .normal)
        } else {
            button.setTitle(row.buttonTitle, for: .normal)
        }
        button.isHidden = row.buttonTitle?.isEmpty != false
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        guard currentAssociatedRow?.selectionAction != nil else { return }
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
