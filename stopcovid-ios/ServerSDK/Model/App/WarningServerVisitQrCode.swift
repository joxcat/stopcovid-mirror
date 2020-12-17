// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WarningServerVisitQrCode.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

public struct WarningServerVisitQrCode: RBServerBody {

    public let type: String
    public let venueType: String
    public let venueCategory: Int?
    public let venueCapacity: Int?
    public let uuid: String
    
    public init(type: String, venueType: String, venueCategory: Int?, venueCapacity: Int?, uuid: String) {
        self.type = type
        self.venueType = venueType
        self.venueCategory = venueCategory
        self.venueCapacity = venueCapacity
        self.uuid = uuid
    }
    
}
