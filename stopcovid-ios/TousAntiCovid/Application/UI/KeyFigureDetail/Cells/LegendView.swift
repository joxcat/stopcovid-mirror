// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LegendView.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import UIKit

final class LegendView: UIView, Xibbed {
 
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var label: UILabel!
    
    static func view(legend: KeyFigureChartLegend) -> UIView {
        let legendView: LegendView = instantiate()
        legendView.setupUI(legend: legend)
        legendView.setupContent(legend: legend)
        return legendView
    }
    
    private func setupUI(legend: KeyFigureChartLegend) {
        label.font = Appearance.Chart.legendFont
        label.textColor = legend.color
        imageView.tintColor = legend.color
    }
    
    private func setupContent(legend: KeyFigureChartLegend) {
        label.text = legend.title
        imageView.image = legend.image
    }
    
}
