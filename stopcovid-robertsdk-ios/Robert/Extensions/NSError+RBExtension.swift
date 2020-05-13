// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSError+RBExtension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import Foundation

extension NSError {
    
    static func rbLocalizedError(message: String, code: Int) -> Error {
        return NSError(domain: "Robert-SDK", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
}
