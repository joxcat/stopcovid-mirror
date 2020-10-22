/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/19 - for the TousAntiCovid project
 */

import Foundation

/// A proximity payload.
public struct ProximityPayload: Equatable {
    
    /// The number of bytes in the payload.
    public static let byteCount = 16
    
    /// The payload data.
    public let data: Data
    
    /// Creates a proximity payload from the specified data.
    /// - Parameter data: The payload data. Must contain exactly 16 bytes.
    public init?(data: Data) {
        guard data.count == ProximityPayload.byteCount else {
            return nil
        }
        
        self.data = data
    }
}
