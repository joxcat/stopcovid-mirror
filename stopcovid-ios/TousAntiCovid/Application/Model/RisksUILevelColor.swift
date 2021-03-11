// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RisksUILevelColor.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/02/2021 - for the TousAntiCovid project.
//

import UIKit

struct RisksUILevelColor: Codable {
    
    let from: String
    let to: String
    
    var fromColor: UIColor { UIColor(hexString: from) }
    var toColor: UIColor { UIColor(hexString: to) }
    
}
