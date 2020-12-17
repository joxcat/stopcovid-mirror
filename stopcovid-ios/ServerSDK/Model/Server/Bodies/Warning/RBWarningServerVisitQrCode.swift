// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBWarningServerVisitQrCode.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBWarningServerVisitQrCode: RBServerBody {

    let type: String
    let venueType: String
    let venueCategory: Int?
    let venueCapacity: Int?
    let uuid: String
    
    static func from(visitQrCode: WarningServerVisitQrCode) -> RBWarningServerVisitQrCode {
        RBWarningServerVisitQrCode(type: visitQrCode.type,
                                   venueType: visitQrCode.venueType,
                                   venueCategory: visitQrCode.venueCategory,
                                   venueCapacity: visitQrCode.venueCapacity,
                                   uuid: visitQrCode.uuid)
    }
    
}
