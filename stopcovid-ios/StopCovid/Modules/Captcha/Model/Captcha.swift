//
//  Captcha.swift
//  StopCovid
//
//  Created by Nicolas on 05/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

struct Captcha {

    let id: String
    let image: UIImage?
    let audio: Data?
    
    var isImage: Bool { image != nil }
    
}
