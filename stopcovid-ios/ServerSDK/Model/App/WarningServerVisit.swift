// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WarningServerVisit.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

public struct WarningServerVisit: RBServerBody {

    public let timestamp: String
    public let qrCode: WarningServerVisitQrCode
    
    public init(timestamp: String, qrCode: WarningServerVisitQrCode) {
        self.timestamp = timestamp
        self.qrCode = qrCode
    }
    
}
