// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CaptchaConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

enum CaptchaConstant {

    enum Url {
        
        static var create: URL { Constant.Server.baseUrl.appendingPathComponent("/captcha") } // PROD Version (Cap Backend)
        
        static func getImage(id: String) -> URL { Constant.Server.baseUrl.appendingPathComponent("/captcha/\(id)/image") } // PROD Version (Cap Backend)
        
        static func getAudio(id: String) -> URL { Constant.Server.baseUrl.appendingPathComponent("/captcha/\(id)/audio") } // PROD Version (Cap Backend)
        
    }
}
