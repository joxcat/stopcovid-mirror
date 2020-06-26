//
//  CaptchaGenerationResponse.swift
//  StopCovid
//
//  Created by Nicolas on 04/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

struct CaptchaGenerationResponse: CaptchaServerResponse {

    let id: String
    let captchaId: String
    
}
