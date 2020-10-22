// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigure.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

struct KeyFigure: Codable {
    
    enum Category: String, Codable {
        case health
        case app
    }
    
    let labelKey: String
    let category: Category
    let valueGlobalToDisplay: String
    let valueGlobal: Double?
    let isFeatured: Bool
    let lastUpdate: Int
    
    var label: String { "\(labelKey).label".localized }
    var shortLabel: String { "\(labelKey).shortLabel".localized }
    var description: String { "\(labelKey).description".localized }
    var color: UIColor {
        let colorCode: String = UIColor.isDarkMode ? "\(labelKey).colorCode.dark".localized : "\(labelKey).colorCode.light".localized
        return UIColor(hexString: colorCode)
    }
    
    var formattedDate: String {
        Date(timeIntervalSince1970: Double(lastUpdate)).relativelyFormatted()
    }
    
}
