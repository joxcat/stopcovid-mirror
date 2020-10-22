// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaServerResponse.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the TousAntiCovid project.
//

import Foundation

protocol CaptchaServerResponse: Decodable {

    static func from(data: Data) throws -> Self
    
}

extension CaptchaServerResponse {
    
    static func from(data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
}
