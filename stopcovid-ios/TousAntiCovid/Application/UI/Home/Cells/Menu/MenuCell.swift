// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MenuCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class MenuCell: CVTableViewCell {
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var imageView1: UIImageView!
    @IBOutlet private var imageView2: UIImageView!
    @IBOutlet private var imageView3: UIImageView!
    @IBOutlet private var imageView4: UIImageView!
    @IBOutlet private var imageView5: UIImageView!
    @IBOutlet private var imageView6: UIImageView!
    @IBOutlet private var label1: UILabel!
    @IBOutlet private var label2: UILabel!
    @IBOutlet private var label3: UILabel!
    @IBOutlet private var label4: UILabel!
    @IBOutlet private var label5: UILabel!
    @IBOutlet private var label6: UILabel!
    @IBOutlet private var separators: [UIView] = []
    @IBOutlet private var stackViews: [UIStackView] = []
    @IBOutlet private var buttons: [UIButton] = []
    
    private var labels: [UILabel] { [label1, label2, label3, label4, label5, label6] }
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
        setupContent(row: row)
    }
    
    private func setupUI() {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        let shouldShowLastRow: Bool = currentAssociatedRow?.senarySelectionAction != nil
        stackViews.last?.isHidden = !shouldShowLastRow
        buttons.last?.isHidden = !shouldShowLastRow
        separators.last?.isHidden = !shouldShowLastRow
        setupAccessibility()
    }
    
    private func setupContent(row: CVRow) {
        imageView1.tintColor = row.theme.imageTintColor
        imageView2.tintColor = row.theme.imageTintColor
        imageView3.tintColor = row.theme.imageTintColor
        imageView4.tintColor = row.theme.imageTintColor
        imageView5.tintColor = row.theme.imageTintColor
        imageView6.tintColor = row.theme.imageTintColor

        imageView1.image = Asset.Images.search.image
        imageView2.image = Asset.Images.document.image
        imageView3.image = Asset.Images.manageData.image
        imageView4.image = Asset.Images.privacy.image
        imageView5.image = Asset.Images.about.image
        imageView6.image = Asset.Images.tabBarSupportNormal.image

        label1.textColor = row.theme.titleColor
        label2.textColor = row.theme.titleColor
        label3.textColor = row.theme.titleColor
        label4.textColor = row.theme.titleColor
        label5.textColor = row.theme.titleColor
        label6.textColor = row.theme.titleColor

        label1.font = row.theme.titleFont()
        label2.font = row.theme.titleFont()
        label3.font = row.theme.titleFont()
        label4.font = row.theme.titleFont()
        label5.font = row.theme.titleFont()
        label6.font = row.theme.titleFont()

        label1.text = "home.moreSection.testingSites".localized
        label2.text = "home.moreSection.curfewCertificate".localized
        label3.text = "home.moreSection.manageData".localized
        label4.text = "home.moreSection.privacy".localized
        label5.text = "home.moreSection.aboutStopCovid".localized
        label6.text = "home.moreSection.support".localized
        buttons.forEach {
            $0.setBackgroundImage(UIImage(color: .clear), for: .normal)
            $0.setBackgroundImage(UIImage(color: Asset.Colors.cellSelectionColor.color), for: .highlighted)
        }
        separators.forEach { $0.backgroundColor = Asset.Colors.separator.color.withAlphaComponent(0.2) }
    }
    
    private func setupAccessibility() {
        (0..<labels.count).forEach {
            labels[$0].isAccessibilityElement = false
            buttons[$0].isAccessibilityElement = true
            buttons[$0].accessibilityLabel = labels[$0].text
        }
    }
    
    @IBAction private func button1Pressed(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
    @IBAction private func button2Pressed(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
    @IBAction private func button3Pressed(_ sender: Any) {
        currentAssociatedRow?.tertiarySelectionAction?()
    }
    
    @IBAction private func button4Pressed(_ sender: Any) {
        currentAssociatedRow?.quaternarySelectionAction?()
    }
    
    @IBAction private func button5Pressed(_ sender: Any) {
        currentAssociatedRow?.quinarySelectionAction?()
    }

    @IBAction private func button6Pressed(_ sender: Any) {
        currentAssociatedRow?.senarySelectionAction?()
    }
    
}
