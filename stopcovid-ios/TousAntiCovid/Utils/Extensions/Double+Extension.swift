// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Double+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation

extension Double {
    
    var truncatedStringValue: String { "\(Int(self))" }
    
    func shrinkedValue() -> Double {
        let newValue: Double
        if self < 10.0 {
            newValue = Double(Int(self * 100.0)) / 100.0
        } else if self < 100.0 {
            newValue = Double(Int(self * 10.0)) / 10.0
        } else {
            newValue = Double(Int(self))
        }
        return newValue
    }
    
}
