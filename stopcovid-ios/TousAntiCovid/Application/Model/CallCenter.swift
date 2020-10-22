// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CallCenter.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/05/2020 - for the TousAntiCovid project.
//


import Foundation

struct CallCenter: Codable {

    let tel: String
    let label: [String: String]
    
    var localizedLabel: String? { label[Locale.currentLanguageCode] }
    
}
