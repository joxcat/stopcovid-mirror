// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesHistoryEmptyView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class VenuesHistoryEmptyView: UIView {
    
    @IBOutlet private var titleLabel: UILabel!
    
    static func view() -> UIView {
        Bundle.main.loadNibNamed("VenuesHistoryEmptyView", owner: nil, options: nil)![0] as! UIView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initUI()
    }
    
    private func initUI() {
        titleLabel.text = "venuesHistoryController.noVenuesEmptyView.title".localized
        titleLabel.font = Appearance.Cell.Text.titleFont
    }
    
    @IBAction private func buttonDidPress(_ sender: Any) {
        InfoCenterManager.shared.refetchContent()
    }
    
}
