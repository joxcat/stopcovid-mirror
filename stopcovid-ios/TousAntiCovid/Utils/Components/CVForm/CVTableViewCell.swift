// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVTableViewCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

class CVTableViewCell: UITableViewCell {

    var currentAssociatedRow: CVRow?
    
    @IBOutlet var cvTitleLabel: UILabel?
    @IBOutlet var cvSubtitleLabel: UILabel?
    @IBOutlet var cvAccessoryLabel: UILabel?
    @IBOutlet var cvImageView: UIImageView?
    
    @IBOutlet private var leadingConstraint: NSLayoutConstraint?
    @IBOutlet private var trailingConstraint: NSLayoutConstraint?
    @IBOutlet private var topConstraint: NSLayoutConstraint?
    @IBOutlet private var bottomConstraint: NSLayoutConstraint?
    @IBOutlet private var imageWidthConstraint: NSLayoutConstraint?
    @IBOutlet private var imageHeightConstraint: NSLayoutConstraint?
    
    func setup(with row: CVRow) {
        currentAssociatedRow = row
        cvSubtitleLabel?.text = row.subtitle
        cvAccessoryLabel?.text = row.accessoryText
        cvImageView?.image = row.image
        cvImageView?.tintColor = row.theme.imageTintColor
        setupTheme(with: row)
        setupAccessibility()
    }
    
    private func setupTheme(with row: CVRow) {
        selectionStyle = row.selectionAction == nil ? .none : .default
        accessoryType = row.selectionAction == nil ? .none : .disclosureIndicator
        backgroundColor = row.theme.backgroundColor ?? .clear
        
        cvTitleLabel?.isHidden = row.title == nil
        cvTitleLabel?.textAlignment = row.theme.textAlignment
        cvTitleLabel?.adjustsFontForContentSizeCategory = true
        
        if let titleHighlightText = row.titleHighlightText, let title = row.title {
            let range: NSRange = (title as NSString).range(of: titleHighlightText)
            let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: title, attributes: [.foregroundColor: row.theme.titleColor,
                                                                                                                  .font: row.theme.titleFont()])
            attributedText.addAttributes([.foregroundColor: row.theme.titleHighlightColor, .font: row.theme.titleHighlightFont()], range: range)
            cvTitleLabel?.attributedText = attributedText
        } else {
            cvTitleLabel?.font = row.theme.titleFont()
            cvTitleLabel?.textColor = row.theme.titleColor
            cvTitleLabel?.text = row.title
        }
        
        cvSubtitleLabel?.isHidden = row.subtitle == nil
        cvSubtitleLabel?.font = row.theme.subtitleFont()
        cvSubtitleLabel?.textColor = row.theme.subtitleColor
        cvSubtitleLabel?.textAlignment = row.theme.textAlignment
        cvSubtitleLabel?.adjustsFontForContentSizeCategory = true
        
        cvAccessoryLabel?.isHidden = row.accessoryText == nil
        cvAccessoryLabel?.font = row.theme.accessoryTextFont?()
        cvAccessoryLabel?.textAlignment = row.theme.textAlignment
        cvAccessoryLabel?.adjustsFontForContentSizeCategory = true
        
        cvImageView?.isHidden = row.image == nil
        
        leadingConstraint?.constant = row.theme.leftInset ?? Appearance.Cell.leftMargin
        trailingConstraint?.constant = row.theme.rightInset ?? Appearance.Cell.rightMargin
        if let topInset = row.theme.topInset {
            topConstraint?.constant = topInset
        }
        if let bottomInset = row.theme.bottomInset {
            bottomConstraint?.constant = bottomInset
        }
        if let imageWidthConstraint = imageWidthConstraint, let imageHeightConstraint = imageHeightConstraint{
            if let ratio = row.theme.imageRatio {
                if let imageView = cvImageView {
                    let existingConstraint: NSLayoutConstraint? = imageView.constraints.filter { $0.firstAnchor == imageView.widthAnchor && $0.secondAnchor == imageView.heightAnchor }.first
                    if let constraint = existingConstraint {
                        imageView.removeConstraint(constraint)
                    }
                    imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: ratio, constant: 0.0).isActive = true
                }
                imageHeightConstraint.isActive = false
            } else {
                if let imageView = cvImageView {
                    let existingConstraint: NSLayoutConstraint? = imageView.constraints.filter { $0.firstAnchor == imageView.widthAnchor && $0.secondAnchor == imageView.heightAnchor }.first
                    if let constraint = existingConstraint {
                        imageView.removeConstraint(constraint)
                    }
                }
                imageHeightConstraint.isActive = true
            }
            if let size = row.theme.imageSize {
                imageWidthConstraint.constant = size.width
                imageHeightConstraint.constant = size.height
            }
        }
        let leftInset: CGFloat? = row.theme.separatorLeftInset
        let rightInset: CGFloat? = row.theme.separatorRightInset
        if leftInset == nil && rightInset == nil {
            hideSeparator()
        } else {
            separatorInset = UIEdgeInsets(top: 0.0, left: leftInset ?? 0.0, bottom: 0.0, right: rightInset ?? 0.0)
        }
    }
    
    private func setupAccessibility() {
        cvImageView?.isAccessibilityElement = false
        
        cvTitleLabel?.isAccessibilityElement = true
        cvTitleLabel?.accessibilityLabel = cvTitleLabel?.text?.removingEmojis()
        cvTitleLabel?.accessibilityTraits = .staticText
        
        cvSubtitleLabel?.isAccessibilityElement = true
        cvSubtitleLabel?.accessibilityLabel = cvSubtitleLabel?.text?.removingEmojis()
        cvSubtitleLabel?.accessibilityTraits = .staticText
        
        cvAccessoryLabel?.isAccessibilityElement = true
        cvAccessoryLabel?.accessibilityLabel = cvAccessoryLabel?.text?.removingEmojis()
        cvAccessoryLabel?.accessibilityTraits = .staticText
    }
    
}
