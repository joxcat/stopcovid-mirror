// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBStatusRiskLevelInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/02/2021 - for the TousAntiCovid project.
//

import Foundation

public struct RBStatusRiskLevelInfo: Codable {
    
    public var riskLevel: Double
    public let lastContactDate: Date?
    public let lastRiskScoringDate: Date?
    
    public init(riskLevel: Double, lastContactDate: Date?, lastRiskScoringDate: Date?) {
        self.riskLevel = riskLevel
        self.lastContactDate = lastContactDate
        self.lastRiskScoringDate = lastRiskScoringDate
    }
    
}
