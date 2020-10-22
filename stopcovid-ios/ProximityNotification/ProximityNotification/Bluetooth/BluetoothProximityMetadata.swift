/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import Foundation

/// The Bluetooth metadata associated with proximity information.
public struct BluetoothProximityMetadata: ProximityMetadata {
    
    /// The raw received signal strength indicator (RSSI), in decibels.
    public let rawRSSI: Int
    
    /// A calibrated value of the received signal strength indicator (RSSI), in decibels.
    public let calibratedRSSI: Int
    
    /// The transmitting power level.
    public let txPowerLevel: Int
}
