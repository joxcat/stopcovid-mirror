// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBLocalProximity.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the TousAntiCovid project.
//

import UIKit

public struct RBLocalProximity: Hashable {

    public let ecc: String
    public let ebid: String
    public let mac: String
    public let timeFromHelloMessage: UInt16
    public let timeCollectedOnDevice: Int
    public let rssiRaw: Int
    public var rssiCalibrated: Int
    public let tx: Int

    public init(ecc: String, ebid: String, mac: String, timeFromHelloMessage: UInt16, timeCollectedOnDevice: Int, rssiRaw: Int, rssiCalibrated: Int, tx: Int) {
        self.ecc = ecc
        self.ebid = ebid
        self.mac = mac
        self.timeFromHelloMessage = timeFromHelloMessage
        self.timeCollectedOnDevice = timeCollectedOnDevice
        self.rssiRaw = rssiRaw
        self.rssiCalibrated = rssiCalibrated
        self.tx = tx
    }
    
}
