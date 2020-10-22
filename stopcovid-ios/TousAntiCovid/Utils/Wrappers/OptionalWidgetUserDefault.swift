// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OptionalWidgetUserDefault.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2019.
//

import UIKit

@propertyWrapper
final class OptionalWidgetUserDefault<T> {
    
    private let defaults: UserDefaults = .widget
    let key: WidgetUserDefault<T>.Key
    
    var projectedValue: String { key.rawValue }
    
    var wrappedValue: T? {
        get { defaults.object(forKey: key.rawValue) as? T }
        set {
            if newValue == nil {
                defaults.removeObject(forKey: key.rawValue)
            } else {
                defaults.set(newValue, forKey: key.rawValue)
            }
            defaults.synchronize()
        }
    }

    init(wrappedValue: T? = nil, key: WidgetUserDefault<T>.Key) {
        self.key = key
    }
    
}
