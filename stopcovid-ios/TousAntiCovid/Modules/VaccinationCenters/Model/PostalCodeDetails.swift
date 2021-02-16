// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PostalCodeDetails.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/01/2021 - for the TousAntiCovid project.
//

import Foundation

struct PostalCodeDetails: Decodable {
    
    let latitude: Double
    let longitude: Double
    let department: String
    
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "long"
        case department = "dept"
    }
    
}
