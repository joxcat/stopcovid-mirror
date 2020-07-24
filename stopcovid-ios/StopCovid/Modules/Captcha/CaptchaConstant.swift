//
//  CaptchaConstant.swift
//  StopCovid
//
//  Created by Nicolas on 12/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

enum CaptchaConstant {

    enum Url {
        
        static var create: URL { Constant.Server.baseUrl.appendingPathComponent("/captcha") } // PROD Version (Cap Backend)
        
        static func getImage(id: String) -> URL { Constant.Server.baseUrl.appendingPathComponent("/captcha/\(id)/image") } // PROD Version (Cap Backend)
        
        static func getAudio(id: String) -> URL { Constant.Server.baseUrl.appendingPathComponent("/captcha/\(id)/audio") } // PROD Version (Cap Backend)
        
    }
}
