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

// MARK: - Line chart -
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

    private var defaultCircleWidth: CGFloat { 4.0 }
    private var minCircleWidth: CGFloat { 1.75 }
    private var circleResizingThreshold: Int { 25 }
    private var circleWidthFactorFromLineWidth: CGFloat { 2.0 }

    func setupStyle(color: UIColor, entriesCount: Int) {
        drawValuesEnabled = false
        circleRadius = ((defaultCircleWidth * CGFloat(circleResizingThreshold)) / CGFloat(entriesCount)).clamped(to: minCircleWidth...defaultCircleWidth)
        lineWidth = circleRadius / circleWidthFactorFromLineWidth
        setColor(color)
        setCircleColor(color)
        drawCircleHoleEnabled = false
    }

}

// MARK: - Bar chart -
extension BarChartView {

    func setupStyle() {
        legend.enabled = false
        chartDescription?.enabled = false
        isUserInteractionEnabled = false
        extraTopOffset = 10.0
        extraBottomOffset = 16.0
        rightAxis.enabled = false
        minOffset = 0.0
        setScaleEnabled(false)
    }

}

extension BarChartDataSet {

    func setupStyle(color: UIColor, entriesCount: Int) {
        drawValuesEnabled = false
        colors = [color]
    }

}

extension BarChartData {
    
    func setupStyle(entriesCount: Int) {
        let xValuesDiff: Double = xMax - xMin
        let spacing: Double = 0.05
        barWidth = xValuesDiff / Double(entriesCount) - (spacing * xValuesDiff / Double(entriesCount + 1))
    }
    
}


// MARK: - Axis -
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
