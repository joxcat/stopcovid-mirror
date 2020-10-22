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

/// A protocol for metadata associated with proximity information.
public protocol ProximityMetadata {}

/// A structure that contains proximity information.
public struct ProximityInfo {
    
    /// The received payload.
    public let payload: ProximityPayload
    
    /// The date when these proximity information were retrieved.
    public let timestamp: Date
    
    /// The associated metadata.
    public let metadata: ProximityMetadata
}
