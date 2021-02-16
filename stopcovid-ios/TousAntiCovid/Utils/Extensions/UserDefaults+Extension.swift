// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserDefaults+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import Foundation

extension UserDefaults {
    
    static var widget: UserDefaults { UserDefaults(suiteName: "group.fr.gouv.stopcovid.ios.contents")! }
    
}
