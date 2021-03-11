// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RisksUILevelSectionLink.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/02/2021 - for the TousAntiCovid project.
//

import Foundation

struct RisksUILevelSectionLink: Codable {
    
    enum LinkType: String, Codable {
        case web
        case ctrl
    }
    
    let label: String
    let action: String
    let type: LinkType
    
}
