// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoTag.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

struct InfoTag: Codable {
    
    let id: String
    let labelKey: String
    let colorCode: String
    
    var label: String { labelKey.infoCenterLocalized }
    var color: UIColor { UIColor(hexString: colorCode) }
    
}
