// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserDefault.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2019.
//

import UIKit

@propertyWrapper
final class UserDefault<T> {
    
    let defaults: UserDefaults = .standard
    let key: Key
    let defaultValue: T
    
    var projectedValue: String { key.rawValue }
    
    var wrappedValue: T {
        get { defaults.object(forKey: key.rawValue) as? T ?? defaultValue }
        set {
            defaults.set(newValue, forKey: key.rawValue)
            defaults.synchronize()
        }
    }

    init(wrappedValue: T, key: Key) {
        self.defaultValue = wrappedValue
        self.key = key
    }
    
}

extension UserDefault {
    
    enum Key: String {
        case isAppAlreadyInstalled = "isAppAlreadyInstalled_v2"
        case isOnboardingDone = "isOnboardingDone_v2"
        case lastStringsUpdateDate
        case lastStringsLanguageCode
        case lastMaintenanceUpdateDate
        case lastReceivedApnsTimestamps
        
        case lastStatusBackgroundFetchTimestamp
        case lastStatusBackgroundFetchDidSucceed
        case lastNotificationTimestamp
    }
    
}
