//
//  CaptchaValidationResponse.swift
//  StopCovid
//
//  Created by Nicolas on 05/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

struct CaptchaValidationResponse: CaptchaServerResponse {

    enum ResultType: String, Decodable {
        case success = "SUCCESS"
        case failed = "FAILED"
    }
    
    let result: ResultType?
    let code: String?
    let message: String?
    
}
