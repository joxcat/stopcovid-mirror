// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSErrorExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/02/2020 - for the TousAntiCovid project.
//

import UIKit

extension NSError {
    
    static func localizedError(message: String, code: Int) -> Error {
        return NSError(domain: UIApplication.shared.bundleIdentifier, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
}
