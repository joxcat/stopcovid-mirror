// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServerStatusResponse.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import UIKit

struct RBServerStatusResponse: RBServerResponse {

    var atRisk: Bool
    var lastExposureTimeframe: Int?
    var message: String?
    var tuples: String

}
