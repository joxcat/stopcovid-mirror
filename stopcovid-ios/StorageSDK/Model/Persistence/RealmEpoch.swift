// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RealmEpoch.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RealmSwift
import RobertSDK

final class RealmEpoch: Object {

    @objc dynamic var epochId: Int = 0
    @objc dynamic var ebid: String!
    @objc dynamic var ecc: String!
    
    static func from(epoch: RBEpoch) -> RealmEpoch {
        RealmEpoch(epochId: epoch.epochId, ebid: epoch.key.ebid, ecc: epoch.key.ecc)
    }
    
    convenience init(epochId: Int, ebid: String, ecc: String) {
        self.init()
        self.epochId = epochId
        self.ebid = ebid
        self.ecc = ecc
    }
    
    override class func primaryKey() -> String? {
        return "epochId"
    }
    
    override class func indexedProperties() -> [String] {
        return ["epochId"]
    }
    
    func toRBEpoch() -> RBEpoch {
        RBEpoch(epochId: epochId, key: RBEpochKey(ebid: ebid, ecc: ecc))
    }
    
}
