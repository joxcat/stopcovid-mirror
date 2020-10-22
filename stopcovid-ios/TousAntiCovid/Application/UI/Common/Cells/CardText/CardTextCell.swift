// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CardTextCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class CardTextCell: CVTableViewCell {

    @IBOutlet private var containerView: UIView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        containerView.layer.cornerRadius = 10.0
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
    }
    
}
