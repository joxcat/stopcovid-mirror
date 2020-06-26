//
//  CaptchaValidationBody.swift
//  StopCovid
//
//  Created by Nicolas on 05/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

struct CaptchaValidationBody: CaptchaServerBody {

    let id: String
    let answer: String
    
}
