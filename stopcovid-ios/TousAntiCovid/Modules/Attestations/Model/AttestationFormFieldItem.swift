// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationFormFieldItem.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import Foundation

struct AttestationFormFieldItem: Codable {
    
    let code: String
    
    var shortLabel: String { "attestation.form.\(code).shortLabel".localized }
    var longLabel: String { "attestation.form.\(code).longLabel".localized }
    
}
