// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBWarningServerVisit.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBWarningServerVisit: RBServerBody {

    let timestamp: String
    let qrCode: RBWarningServerVisitQrCode
    
    static func from(visit: WarningServerVisit) -> RBWarningServerVisit {
        RBWarningServerVisit(timestamp: visit.timestamp,
                             qrCode: RBWarningServerVisitQrCode.from(visitQrCode: visit.qrCode))
    }
    
}
