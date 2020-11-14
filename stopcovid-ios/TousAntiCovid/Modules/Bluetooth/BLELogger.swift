// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BLELogger.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import Foundation
import ProximityNotification

final class BLELogger: ProximityNotificationLoggerProtocol {
    
    var minimumLogLevel: ProximityNotificationLoggerLevel = .error
    
    func log(logLevel: ProximityNotificationLoggerLevel, message: @autoclosure () -> String, source: @autoclosure () -> String) {
    }
}
