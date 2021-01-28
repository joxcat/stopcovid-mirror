// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ChartsValueFormatter.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation
import Charts

final class ChartsValueFormatter: IAxisValueFormatter {

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        let string: String
        if value < 1_000.0 {
            string = formatter.string(from: NSNumber(value: value.shrinkedValue()))!
        } else if value < 1_000_000.0 {
            string = formatter.string(from: NSNumber(value: (value / 1000.0).shrinkedValue()))! + "K"
        } else {
            string = formatter.string(from: NSNumber(value: (value / 1_000_000.0).shrinkedValue()))! + "M"
        }
        return string
    }

}
