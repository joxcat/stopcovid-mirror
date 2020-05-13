// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBLocalProximity.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import UIKit

struct RBLocalProximity {

    let ecc: String
    let ebid: String
    let mac: String
    let timeFromHelloMessage: UInt16
    let timeCollectedOnDevice: Int
    let rssiRaw: Int
    let rssiCalibrated: Int

}
