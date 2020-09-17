// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServerRegisterBodyV3.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 12/06/2020 - for the STOP-COVID project.
//

import Foundation

struct RBServerRegisterBodyV3: RBServerBody {

    var captcha: String
    var captchaId: String
    var clientPublicECDHKey: String
    var pushInfo: RBServerPushInfo
    
}
