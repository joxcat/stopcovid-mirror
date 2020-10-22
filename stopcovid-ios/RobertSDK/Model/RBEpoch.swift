// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBEpoch.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the TousAntiCovid project.
//

import UIKit

public struct RBEpoch: Decodable {
    
    public let epochId: Int
    public let key: RBEpochKey
    
    public init(epochId: Int, key: RBEpochKey) {
        self.epochId = epochId
        self.key = key
    }
    
}
