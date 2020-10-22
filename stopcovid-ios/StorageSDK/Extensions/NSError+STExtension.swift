// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSError+STExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/02/2020 - for the TousAntiCovid project.
//

import Foundation

extension NSError {
    
    static func stLocalizedError(message: String, code: Int) -> Error {
        return NSError(domain: "Storage-SDK", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
}
