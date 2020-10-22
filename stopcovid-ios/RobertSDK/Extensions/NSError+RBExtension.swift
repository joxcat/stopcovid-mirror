// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSError+RBExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/02/2020 - for the TousAntiCovid project.
//

import Foundation

extension NSError {
    
    static var lostConnectionCode: Int { -997 }
    static var timeoutCode: Int { -1001 }
    
    static func rbLocalizedError(message: String, code: Int) -> Error {
        return NSError(domain: "Robert-SDK", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
}
