// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaServerBody.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the TousAntiCovid project.
//

import Foundation

protocol CaptchaServerBody: Encodable {

    func toData() throws -> Data
    
}

extension CaptchaServerBody {
    
    func toData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
}
