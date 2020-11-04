// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Attestation+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/05/2020 - for the TousAntiCovid project.
//

import Foundation
import ServerSDK
import StorageSDK

extension Attestation {
    
    var isExpired: Bool { Date().timeIntervalSince1970 - Double(timestamp) > ParametersManager.shared.qrCodeExpiredHours * 3600.0 }
    
}
