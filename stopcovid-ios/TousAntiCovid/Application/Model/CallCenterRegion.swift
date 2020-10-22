// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CallCenterRegion.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/05/2020 - for the TousAntiCovid project.
//


import Foundation

struct CallCenterRegion: Codable {

    let name: [String: String]
    let callCenters: [CallCenter]
    
    var localizedName: String? { name[Locale.currentLanguageCode] }
    
}
