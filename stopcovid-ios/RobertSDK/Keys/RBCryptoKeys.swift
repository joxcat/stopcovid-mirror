// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBCryptoKeys.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/05/2020 - for the TousAntiCovid project.
//


import UIKit

struct RBCryptoKeys {

    /// Key used to generate mac's sent to the server.
    let ka: Data
    
    /// Key used to decrypt epochs received from the server.
    let kea: Data
    
}
