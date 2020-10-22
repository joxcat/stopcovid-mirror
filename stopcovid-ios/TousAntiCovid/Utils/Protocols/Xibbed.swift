// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Nibbed.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol Xibbed {
    static func instantiate() -> Self
}

extension Xibbed where Self: UIView {
    static func instantiate() -> Self {
        let fullName: String = NSStringFromClass(self)
        let className: String = fullName.components(separatedBy: ".")[1]
        return (Bundle.main.loadNibNamed(className, owner: nil, options: nil) as! [UIView]).first as! Self
    }
}
