// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationsConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import Foundation

enum AttestationsConstant {
    
    static let jsonUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/json/version-\(Constant.Server.jsonVersion)/Attestations/form.json")!
    
}
