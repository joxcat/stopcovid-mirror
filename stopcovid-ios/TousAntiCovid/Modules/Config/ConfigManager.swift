// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ConfigManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/12/2020 - for the TousAntiCovid project.
//

import Foundation
import ServerSDK

final class ConfigManager {
    
    static let shared: ConfigManager = ConfigManager()
    
    @UserDefault(key: .venuesFeaturedWasActivatedAtLeastOneTime)
    private(set) var venuesFeaturedWasActivatedAtLeastOneTime: Bool = false
    
    func fetch(_ completion: @escaping (_ result: Result<Double, Error>) -> ()) {
        ParametersManager.shared.fetchConfig { result in
            if VenuesManager.shared.isVenuesRecordingActivated {
                self.venuesFeaturedWasActivatedAtLeastOneTime = true
            }
            completion(result)
        }
    }
    
}
