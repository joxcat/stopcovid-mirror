// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmVenueQrCode.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 24/11/2020 - for the TousAntiCovid project.
//


import UIKit
import RealmSwift
import RobertSDK

final class RealmVenueQrCode: Object {

    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var uuid: String!
    @objc dynamic var qrType: Int = Int()
    @objc dynamic var venueType: String!
    @objc dynamic var ntpTimestamp: Int = Int()
    let venueCategory: RealmOptional<Int> = RealmOptional<Int>()
    let venueCapacity: RealmOptional<Int> = RealmOptional<Int>()
    @objc dynamic var payload: String!


    static func from(venueQrCode: VenueQrCode) -> RealmVenueQrCode {
        RealmVenueQrCode(id: venueQrCode.id,
                         uuid: venueQrCode.uuid,
                         qrType: venueQrCode.qrType,
                         venueType: venueQrCode.venueType,
                         ntpTimestamp: venueQrCode.ntpTimestamp,
                         venueCategory: venueQrCode.venueCategory,
                         venueCapacity: venueQrCode.venueCapacity,
                         payload: venueQrCode.payload)
    }

    convenience init(id: String, uuid: String, qrType: Int, venueType: String, ntpTimestamp: Int, venueCategory: Int?, venueCapacity: Int?, payload: String) {
        self.init()
        self.id = id
        self.uuid = uuid
        self.qrType = qrType
        self.venueType = venueType
        self.ntpTimestamp = ntpTimestamp
        self.venueCategory.value = venueCategory
        self.venueCapacity.value = venueCapacity
        self.payload = payload
    }

    override class func primaryKey() -> String? {
        return "id"
    }

    override class func indexedProperties() -> [String] {
        return ["id"]
    }

    func toVenueQrCode() -> VenueQrCode {
        VenueQrCode(id: id,
                    uuid: uuid,
                    qrType: qrType,
                    venueType: venueType,
                    ntpTimestamp: ntpTimestamp,
                    venueCategory: venueCategory.value,
                    venueCapacity: venueCapacity.value,
                    payload: payload)
    }
}
