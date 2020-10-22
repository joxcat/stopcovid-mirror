// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit
import TagListView

final class LinkButtonCell: CVTableViewCell {
    
    @IBOutlet private var button: UIButton!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
    }
    
    private func setupUI() {
        button?.contentHorizontalAlignment = .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        button?.titleLabel?.font = Appearance.Button.linkFont
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
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
}
