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

final class InfoCell: CVTableViewCell {
    
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var tagListView: TagListView!
    @IBOutlet private var button: UIButton!
    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
        setupAccessibility()
    }
    
    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        dateLabel.font = Appearance.Cell.Text.captionTitleFont
        dateLabel.textColor = Appearance.Cell.Text.captionTitleColor
        tagListView.textFont = Appearance.Tag.font
        tagListView.alignment = .left
        tagListView.paddingX = 10.0
        tagListView.paddingY = 5.0
        tagListView.marginX = 6.0
        tagListView.marginY = 6.0
        tagListView.isUserInteractionEnabled = false
        tagListView.backgroundColor = .clear
        cvSubtitleLabel?.font = Appearance.Cell.Text.subtitleFont
        button?.contentHorizontalAlignment = .left
        button?.tintColor = Appearance.Button.Tertiary.titleColor
        button?.titleLabel?.font = Appearance.Button.linkFont
        button?.titleLabel?.adjustsFontForContentSizeCategory = true
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
    }
    
    private func setupContent(row: CVRow) {
        dateLabel.text = row.accessoryText
        if #available(iOS 13.0, *) {
            let imageAttachment: NSTextAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "arrow.up.right.square.fill")?.withRenderingMode(.alwaysTemplate)
            let fullString: NSMutableAttributedString = NSMutableAttributedString(string: "\(row.buttonTitle ?? "") ")
            fullString.append(NSAttributedString(attachment: imageAttachment))
            button.setAttributedTitle(fullString, for: .normal)
        } else {
            button.setTitle(row.buttonTitle, for: .normal)
        }
        button.accessibilityLabel = row.buttonTitle
        button.isHidden = row.buttonTitle?.isEmpty != false
        guard let tags = row.associatedValue as? [InfoTag] else {
            tagListView.isHidden = true
            return
        }
        tagListView.isHidden = tags.isEmpty
        tagListView.removeAllTags()
        tags.forEach {
            let tag: TagView = tagListView.addTag($0.label)
            tag.backgroundColor = $0.color
        }
        tagListView.isAccessibilityElement = true
        tagListView.accessibilityTraits = .staticText
        tagListView.accessibilityLabel = tags.map { $0.label }.joined(separator: ", ")
        tagListView.tagViews.forEach { $0.isAccessibilityElement = false }
        layoutSubviews()
    }
    
    private func setupAccessibility() {
        accessibilityElements = [dateLabel,
                                 cvTitleLabel,
                                 tagListView,
                                 cvSubtitleLabel,
                                 button].compactMap { $0 }
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
}
