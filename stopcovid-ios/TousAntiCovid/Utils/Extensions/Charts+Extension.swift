// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ChartsExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import Foundation
import Charts

extension LineChartView {
    
    func setupStyle() {
        legend.enabled = false
        chartDescription?.enabled = false
        isUserInteractionEnabled = false
        extraBottomOffset = 16.0
        rightAxis.enabled = false
    }
    
}

extension LineChartDataSet {
    
    func setupStyle(color: UIColor) {
        drawValuesEnabled = false
        lineWidth = 2.0
        circleRadius = 4.0
        setColor(color)
        setCircleColor(color)
        drawCircleHoleEnabled = false
    }
    
}

extension YAxis {
    
    func setupStyle() {
        drawAxisLineEnabled = false
        drawLabelsEnabled = true
        drawGridLinesEnabled = true
        gridColor = .lightGray
        setLabelCount(3, force: true)
        labelFont = Appearance.Cell.Text.subtitleFont
        labelTextColor = .gray
        drawTopYLabelEntryEnabled = true
        drawZeroLineEnabled = true
    }
    
}

extension XAxis {
    
    func setupStyle() {
        labelPosition = .bottom
        drawAxisLineEnabled = true
        drawLabelsEnabled = true
        drawGridLinesEnabled = false
        avoidFirstLastClippingEnabled = true
        setLabelCount(2, force: true)
        labelFont = Appearance.Cell.Text.subtitleFont
        labelTextColor = .gray
    }
    
}
