// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmLocalProximity.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RealmSwift
import RobertSDK

final class RealmLocalProximity: Object {

    @objc dynamic var id: String!
    @objc dynamic var ecc: String!
    @objc dynamic var ebid: String!
    @objc dynamic var mac: String!
    @objc dynamic var timeFromHelloMessage: Int = 0
    @objc dynamic var timeCollectedOnDevice: Int = 0
    @objc dynamic var rssiRaw: Int = 0
    @objc dynamic var rssiCalibrated: Int = 0
    @objc dynamic var tx: Int = 0
    
    static func from(localProximity: RBLocalProximity) -> RealmLocalProximity {
        RealmLocalProximity(id: "\(localProximity.ebid)\(localProximity.timeCollectedOnDevice)",
                            ecc: localProximity.ecc,
                            ebid: localProximity.ebid,
                            mac: localProximity.mac,
                            timeFromHelloMessage: Int(localProximity.timeFromHelloMessage),
                            timeCollectedOnDevice: localProximity.timeCollectedOnDevice,
                            rssiRaw: localProximity.rssiRaw,
                            rssiCalibrated: localProximity.rssiCalibrated,
                            tx: localProximity.tx)
    }
    
    convenience init(id: String, ecc: String, ebid: String, mac: String, timeFromHelloMessage: Int, timeCollectedOnDevice: Int, rssiRaw: Int, rssiCalibrated: Int, tx: Int) {
        self.init()
        self.id = id
        self.ecc = ecc
        self.ebid = ebid
        self.mac = mac
        self.timeFromHelloMessage = timeFromHelloMessage
        self.timeCollectedOnDevice = timeCollectedOnDevice
        self.rssiRaw = rssiRaw
        self.rssiCalibrated = rssiCalibrated
        self.tx = tx
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override class func indexedProperties() -> [String] {
        return ["id"]
    }
    
    func toRBLocalProximity() -> RBLocalProximity {
        RBLocalProximity(ecc: ecc,
                         ebid: ebid,
                         mac: mac,
                         timeFromHelloMessage: UInt16(timeFromHelloMessage),
                         timeCollectedOnDevice: timeCollectedOnDevice,
                         rssiRaw: rssiRaw,
                         rssiCalibrated: rssiCalibrated,
                         tx: tx)
    }
    
}
