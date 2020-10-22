// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UITableViewCell+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UITableViewCell {
    
    func hideSeparator() {
        let width: CGFloat = UIScreen.main.bounds.width
        separatorInset = UIEdgeInsets(top: 0.0, left: width / 2.0, bottom: 0.0, right: width / 2.0)
    }
    
}
