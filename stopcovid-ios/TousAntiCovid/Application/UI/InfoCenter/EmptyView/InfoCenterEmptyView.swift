// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCenterEmptyView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class InfoCenterEmptyView: UIView {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var button: CVButton!
    
    static func view() -> UIView {
        Bundle.main.loadNibNamed("InfoCenterEmptyView", owner: nil, options: nil)![0] as! UIView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initUI()
    }
    
    private func initUI() {
        titleLabel.text = "infoCenterController.noInternet.title".localized
        titleLabel.font = Appearance.Cell.Text.titleFont
        subtitleLabel.text = "infoCenterController.noInternet.subtitle".localized
        subtitleLabel.font = Appearance.Cell.Text.subtitleFont
        button.setTitle("common.retry".localized, for: .normal)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    @IBAction private func buttonDidPress(_ sender: Any) {
        InfoCenterManager.shared.refetchContent()
    }
    
}
