// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSError+SVExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 01/06/2020 - for the TousAntiCovid project.
//

import UIKit

extension NSError {
    
    static func svLocalizedError(message: String, code: Int) -> Error {
        return NSError(domain: "Server-SDK", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    static let deviceTime: Error = svLocalizedError(message: "Device time not aligned to server time", code: -1)
    
}
