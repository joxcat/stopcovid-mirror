// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureDepartment.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

struct KeyFigureDepartment: Codable {
    
    let number: String
    let label: String
    let extractDate: Int
    let value: Double?
    let valueToDisplay: String
    let trend: KeyFigure.Trend?

    var currentTrend: KeyFigure.Trend { trend ?? .same }
    
    var formattedDate: String {
        Date(timeIntervalSince1970: Double(extractDate)).relativelyFormatted()
    }
    
    enum CodingKeys: String, CodingKey {
        case number = "dptNb"
        case label = "dptLabel"
        case extractDate
        case value
        case valueToDisplay
        case trend
    }
    
}
