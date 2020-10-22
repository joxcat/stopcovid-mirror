/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/29 - for the TousAntiCovid project
 */

import Foundation

/// A structure that contains contextual information about a received signal strength indicator (RSSI).
public struct TimestampedRSSI: Equatable {
    
    /// The received signal strength indicator, in dBm.
    public let rssi: Int
    
    /// An identifier associated with the RSSI.
    public let identifier: AnyHashable
    
    /// A date indicating when the RSSI was received.
    public let timestamp: Date
    
    /// Creates a timestamped RSSI.
    /// - Parameters:
    ///   - rssi: The received signal strength indicator, in dBm.
    ///   - identifier: An identifier associated with the RSSI.
    ///   - timestamp: A date indicating when the RSSI was received.
    public init(rssi: Int,
                identifier: AnyHashable,
                timestamp: Date) {
        self.rssi = rssi
        self.identifier = identifier
        self.timestamp = timestamp
    }
}
