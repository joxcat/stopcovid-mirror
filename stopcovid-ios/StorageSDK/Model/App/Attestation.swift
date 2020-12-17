// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Attestation.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import Foundation

public struct Attestation {
    
    public let id: String
    public let timestamp: Int
    public let qrCode: Data
    public let footer: String
    public let qrCodeString: String
    public let reason: String
    
    public init(id: String = UUID().uuidString, timestamp: Int, qrCode: Data, footer: String, qrCodeString: String, reason: String) {
        self.id = id
        self.timestamp = timestamp
        self.qrCode = qrCode
        self.footer = footer
        self.qrCodeString = qrCodeString
        self.reason = reason
    }
    
}
