// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBEpochKey.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/05/2020 - for the TousAntiCovid project.
//


import UIKit

public struct RBEpochKey: Decodable {
    
    public let ebid: String
    public let ecc: String
    
    public init(ebid: String, ecc: String) {
        self.ebid = ebid
        self.ecc = ecc
    }
    
}
