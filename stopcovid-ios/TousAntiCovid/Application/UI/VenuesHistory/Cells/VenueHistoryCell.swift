// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenueHistoryCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class VenueHistoryCell: CVTableViewCell {

    @IBOutlet var trashImageView: UIImageView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        trashImageView.tintColor = Appearance.Cell.Text.subtitleColor.withAlphaComponent(0.5)
        accessoryType = .none
        selectionStyle = .none
    }
    
    @IBAction func didTouchButton(_ sender: Any) {
        currentAssociatedRow?.secondarySelectionAction?()
    }
    
}
