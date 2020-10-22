//
//  RBFiltering.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 05/06/2020 - for the TousAntiCovid project.
//

import Foundation

public protocol RBFiltering {
    
    func filter(proximities: [RBLocalProximity]) throws -> [RBLocalProximity]
    
}
