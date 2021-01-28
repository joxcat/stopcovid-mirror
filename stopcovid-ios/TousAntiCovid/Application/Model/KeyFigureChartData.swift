// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureChartData.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation

struct KeyFigureChartData {
    
    let legend: KeyFigureChartLegend
    let series: [KeyFigureSeriesItem]
    let currentValueToDisplay: String?
    let footer: String?
    let minValue: Double
    let maxValue: Double
    
    var initialValue: Double { series.first?.value ?? 0.0 }
    var lastValue: Double { series.last?.value ?? 0.0 }
    
    init(legend: KeyFigureChartLegend, series: [KeyFigureSeriesItem], currentValueToDisplay: String?, footer: String?) {
        self.legend = legend
        self.series = series
        self.currentValueToDisplay = currentValueToDisplay
        self.footer = footer
        self.minValue = series.min { $0.value < $1.value }?.value ?? 0.0
        self.maxValue = series.max { $0.value < $1.value }?.value ?? 0.0
    }
    
}
