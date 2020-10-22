/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/29 - for the TousAntiCovid project
 */

import Foundation

extension Collection where Element: BinaryInteger {
    
    func mean() -> Double {
        return isEmpty ? 0.0 : Double(reduce(0, +)) / Double(count)
    }
    
    func softmax(factor: Double) -> Double {
        guard factor > 0, !isEmpty else {
            return 0.0
        }
        
        let exponentialSum = reduce(0.0) { $0 + exp(Double($1) / factor) }
        
        return factor * log(exponentialSum / Double(count))
    }
}

extension Collection where Element: BinaryFloatingPoint {
    
    func softmax(factor: Double) -> Double {
        guard factor > 0, !isEmpty else {
            return 0.0
        }
        
        let exponentialSum = reduce(0.0) { $0 + exp(Double($1) / factor) }
        
        return factor * log(exponentialSum / Double(count))
    }
}
