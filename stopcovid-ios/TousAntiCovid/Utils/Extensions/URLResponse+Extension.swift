// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URLResponse+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import Foundation

extension URLResponse {
    
    var responseStatusCode: Int? {
        (self as? HTTPURLResponse)?.statusCode
    }
    
    var isError: Bool? {
        guard let statusCode = responseStatusCode else { return nil }
        return "\(statusCode)".first != "2"
    }
    
}
