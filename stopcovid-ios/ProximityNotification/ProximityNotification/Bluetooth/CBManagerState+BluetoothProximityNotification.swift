/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import CoreBluetooth
import Foundation

extension CBManagerState {
    
    func toProximityNotificationState() -> ProximityNotificationState {
        switch self {
        case .poweredOn:
            return .on
        case .poweredOff:
            return .off
        case .unauthorized:
            return .unauthorized
        case .unsupported:
            return .unsupported
        case .unknown, .resetting:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
