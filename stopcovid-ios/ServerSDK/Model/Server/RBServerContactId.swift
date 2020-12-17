// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServerContactId.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBServerContactId: Codable {

    var timeCollectedOnDevice: Int
    var timeFromHelloMessage: UInt16
    var mac: String
    var rssiRaw: Int
    var rssiCalibrated: Int
    
}
