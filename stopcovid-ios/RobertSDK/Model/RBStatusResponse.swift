//
//  RBStatusResponse.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/04/2020 - for the TousAntiCovid project.
//

import UIKit

public struct RBStatusResponse {

    let riskLevel: Double
    let lastContactDate: String?
    let lastRiskScoringDate: String?
    let message: String?
    let tuples: String
    let declarationToken: String?
    
    public init(riskLevel: Double, lastContactDate: String?, lastRiskScoringDate: String?, message: String?, tuples: String, declarationToken: String?) {
        self.riskLevel = riskLevel
        self.lastContactDate = lastContactDate
        self.lastRiskScoringDate = lastRiskScoringDate
        self.message = message
        self.tuples = tuples
        self.declarationToken = declarationToken
    }

}
