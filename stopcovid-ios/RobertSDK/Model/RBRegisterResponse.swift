// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBRegisterResponse.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import UIKit

public struct RBRegisterResponse {

    let tuples: String
    let timeStart: Int
    let config: [[String: Any]]
    
    public init(tuples: String, timeStart: Int, config: [[String: Any]]) {
        self.tuples = tuples
        self.timeStart = timeStart
        self.config = config
    }
    
}
