// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CACornerMask+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/11/2020 - for the TousAntiCovid project.
//

import UIKit

extension CACornerMask {

    static var all: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
    static var top: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner] }
    static var bottom: CACornerMask { [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
    static var none: CACornerMask { [] }

}
