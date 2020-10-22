// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WidgetUserDefault.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2019.
//

import UIKit

@propertyWrapper
final class WidgetUserDefault<T> {
    
    private let defaults: UserDefaults = .widget
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

extension WidgetUserDefault {
    
    enum Key: String {
        case isOnboardingDone
        case isProximityActivated
        case isSick
        case isRegistered
        case isAtRisk
        case lastStatusReceivedDate
        case lastRiskReceivedDate
        case widgetAppName
        case widgetWelcomeTitle
        case widgetWelcomeButtonTitle
        case widgetActivated
        case widgetDeactivated
        case widgetActivateProximityButtonTitle
        case widgetSmallTitleNoContact
        case widgetSmallTitleAtRisk
        case widgetFullTitleDate
        case widgetFullTitleNoContact
        case widgetFullTitleAtRisk
        case widgetMoreInfo
        case widgetOpenTheApp
        case widgetSickSmallTitle
        case widgetSickFullTitle
        case widgetNoStatusInfo
    }
    
}
