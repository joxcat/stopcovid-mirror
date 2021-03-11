// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RisksUILevel.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/02/2021 - for the TousAntiCovid project.
//

import Foundation

struct RisksUILevel: Codable {
    
    enum ContactDateFormat: String, Codable {
        case date
        case range
        case none
    }
    
    let riskLevel: Double
    let description: String
    let labels: RisksUILevelLabels
    let color: RisksUILevelColor
    private let contactDateFormat: ContactDateFormat?
    let sections: [RisksUILevelSection]
    
    var contactDateFormatType: ContactDateFormat { contactDateFormat ?? .none }
    
}
