// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PrivateEventQRCodeCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/11/2020 - for the TousAntiCovid project.
//

import UIKit

final class PrivateEventQRCodeCell: CVTableViewCell {
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        accessoryType = .none
    }
    
}
