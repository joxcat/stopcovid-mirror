//
//  RBStatusResponse.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the STOP-COVID project.
//

import UIKit

struct RBStatusResponse {

    let atRisk: Bool
    let lastExposureTimeFrame: Int?
    let epochs: [RBEpoch]
    
}
