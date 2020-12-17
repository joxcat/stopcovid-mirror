// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenueQrCode.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/11/2020 - for the TousAntiCovid project.
//

import Foundation

public struct VenueQrCode {

    public let id: String
    public let uuid: String
    public let qrType: Int
    public let venueType: String
    public let ntpTimestamp: Int
    public let venueCategory: Int?
    public let venueCapacity: Int?
    public let payload: String

    public init(id: String, uuid: String, qrType: Int, venueType: String, ntpTimestamp: Int, venueCategory: Int?, venueCapacity: Int?, payload: String) {
        self.id = id
        self.uuid = uuid
        self.qrType = qrType
        self.venueType = venueType
        self.ntpTimestamp = ntpTimestamp
        self.venueCategory = venueCategory
        self.venueCapacity = venueCapacity
        self.payload = payload
    }

}
