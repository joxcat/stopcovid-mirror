// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaValidationResponse.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

struct CaptchaValidationResponse: CaptchaServerResponse {

    enum ResultType: String, Decodable {
        case success = "SUCCESS"
        case failed = "FAILED"
    }
    
    let result: ResultType?
    let code: String?
    let message: String?
    
}
