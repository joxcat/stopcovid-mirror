// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServerRegisterBody.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/06/2020 - for the TousAntiCovid project.
//

import Foundation

struct RBServerRegisterBody: RBServerBody {

    var captcha: String
    var captchaId: String
    var clientPublicECDHKey: String
    var pushInfo: RBServerPushInfo
    
}
