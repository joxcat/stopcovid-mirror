// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBReceivedProximity.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the TousAntiCovid project.
//

import UIKit

public struct RBReceivedProximity {

    public let data: Data
    public let timeCollectedOnDevice: Int
    public let rssiRaw: Int
    public let rssiCalibrated: Int
    public let tx: Int

    public init(data: Data, timeCollectedOnDevice: Int, rssiRaw: Int, rssiCalibrated: Int, tx: Int) {
        self.data = data
        self.timeCollectedOnDevice = timeCollectedOnDevice
        self.rssiRaw = rssiRaw
        self.rssiCalibrated = rssiCalibrated
        self.tx = tx
    }
    
}
