// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Info.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import Foundation

struct Info: Codable {
    
    let titleKey: String
    let descriptionKey: String
    let buttonLabelKey: String?
    let urlKey: String?
    let timestamp: Int
    let tagIds: [String]?
    
    var title: String { titleKey.infoCenterLocalized }
    var description: String { descriptionKey.infoCenterLocalized }
    var buttonLabel: String? { buttonLabelKey?.infoCenterLocalized }
    var url: URL? { URL(string: urlKey?.infoCenterLocalized ?? "") }
    var date: Date { Date(timeIntervalSince1970: Double(timestamp)) }
    var formattedDate: String {
        if Calendar.current.isDateInToday(date) {
            return String(format: "\("common.today".localized), %@", date.timeFormatted())
        } else if Calendar.current.isDateInYesterday(date) {
            return String(format: "\("common.yesterday".localized), %@", date.timeFormatted())
        } else {
            return String(format: "%@, %@", date.dayMonthFormatted(), date.timeFormatted())
        }
    }
    var tags: [InfoTag] { InfoCenterManager.shared.tagsForIds(tagIds ?? []) }
    
}
