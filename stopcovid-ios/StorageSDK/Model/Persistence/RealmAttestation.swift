// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmAttestation.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//


import UIKit
import RealmSwift
import RobertSDK

final class RealmAttestation: Object {

    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var timestamp: Int = 0
    @objc dynamic var qrCode: Data!
    @objc dynamic var footer: String!
    @objc dynamic var qrCodeString: String!
    @objc dynamic var reason: String?
    
    static func from(attestation: Attestation) -> RealmAttestation {
        RealmAttestation(id: attestation.id,
                         timestamp: attestation.timestamp,
                         qrCode: attestation.qrCode,
                         footer: attestation.footer,
                         qrCodeString: attestation.qrCodeString,
                         reason: attestation.reason)
    }
    
    convenience init(id: String, timestamp: Int, qrCode: Data, footer: String, qrCodeString: String, reason: String) {
        self.init()
        self.id = id
        self.timestamp = timestamp
        self.qrCode = qrCode
        self.footer = footer
        self.qrCodeString = qrCodeString
        self.reason = reason
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override class func indexedProperties() -> [String] {
        return ["id"]
    }
    
    func toAttestation() -> Attestation {
        Attestation(id: id,
                    timestamp: timestamp,
                    qrCode: qrCode,
                    footer: footer,
                    qrCodeString: qrCodeString ?? "",
                    reason: reason ?? "")
    }

}
