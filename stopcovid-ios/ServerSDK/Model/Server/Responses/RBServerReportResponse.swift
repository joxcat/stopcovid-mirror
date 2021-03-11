// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServerReportResponse.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 26/11/2020 - for the TousAntiCovid project.
//

import UIKit

struct RBServerReportResponse: RBServerResponse {

    let reportValidationToken: String
    let success: Bool?
    let message: String?
    
}
