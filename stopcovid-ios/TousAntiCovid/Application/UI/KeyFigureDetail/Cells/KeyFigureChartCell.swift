// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigureChartCell.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/01/2021 - for the TousAntiCovid project.
//

import UIKit
import Charts

final class KeyFigureChartCell: CVTableViewCell {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var lineChartView: LineChartView!
    @IBOutlet private var legendStackView: UIStackView!
    @IBOutlet private var footerLabel: UILabel!
    @IBOutlet private var sharingImageView: UIImageView!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        setupUI(with: row)
        setupContent(with: row)
    }

    private func setupUI(with row: CVRow) {
        containerView.backgroundColor = backgroundColor
        backgroundColor = .clear
        containerView.layer.cornerRadius = 10.0
        containerView.layer.maskedCorners = row.theme.maskedCorners
        containerView.layer.masksToBounds = true
        footerLabel.font = Appearance.Cell.Text.captionTitleFont
        footerLabel.textColor = Appearance.Cell.Text.captionTitleColor
        sharingImageView.image = Asset.Images.shareIcon.image
        sharingImageView.tintColor = Appearance.tintColor
    }
    
    private func setupContent(with row: CVRow) {
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let chartDatas = row.associatedValue as? [KeyFigureChartData] else { return }
        let legendViews: [UIView] = chartDatas.map { LegendView.view(legend: $0.legend) }
        legendViews.forEach { legendStackView.addArrangedSubview($0) }
        footerLabel.text = chartDatas.first?.footer
        setupChart(chartDatas: chartDatas)
    }
    
    private func setupChart(chartDatas: [KeyFigureChartData]) {
        let dataSets: [LineChartDataSet] = chartDatas.map {
            let entries: [ChartDataEntry] = $0.series.map { ChartDataEntry(x: $0.date, y: $0.value) }
            let dataSet: LineChartDataSet = LineChartDataSet(entries: entries)
            dataSet.setupStyle(color: $0.legend.color)
            return dataSet
        }
        lineChartView.data = LineChartData(dataSets: dataSets)
        lineChartView.setupStyle()
        lineChartView.leftAxis.setupStyle()
        lineChartView.leftAxis.valueFormatter = ChartsValueFormatter()
        
        let minTodayValue: Double = chartDatas.min { $0.minValue < $1.minValue }?.minValue ?? 0.0
        let maxTodayValue: Double = chartDatas.max { $0.maxValue < $1.maxValue }?.maxValue ?? 0.0
        
        lineChartView.leftAxis.axisMinimum = max(0.0, minTodayValue - (maxTodayValue - minTodayValue) * 0.1)
        lineChartView.leftAxis.removeAllLimitLines()
        
        lineChartView.xAxis.setupStyle()
        lineChartView.xAxis.valueFormatter = ChartsDateFormatter()
        
        let yAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
           viewPortHandler: lineChartView.viewPortHandler,
           yAxis: lineChartView.leftAxis,
           transformer: lineChartView.getTransformer(forAxis: .left)
        )
        lineChartView.leftYAxisRenderer = yAxisRenderer
    }
    
    override func capture() -> UIImage? {
        sharingImageView.isHidden = true
        let image: UIImage = containerView.screenshot()!
        sharingImageView.isHidden = false
        let captureImageView: UIImageView = UIImageView(image: image)
        captureImageView.frame.size = CGSize(width: image.size.width / UIScreen.main.scale, height: image.size.height / UIScreen.main.scale)
        captureImageView.backgroundColor = Appearance.Cell.cardBackgroundColor
        let finalImage: UIImage? = captureImageView.screenshot()
        return finalImage
    }
    
    @IBAction private func didTouchSharingButton(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
    private func limiteLine(chartData: KeyFigureChartData, position: ChartLimitLine.LabelPosition) -> ChartLimitLine {
        let limiteLine: ChartLimitLine = ChartLimitLine(limit: chartData.lastValue, label: chartData.currentValueToDisplay?.formattingValueWithThousandsSeparatorIfPossible() ?? "")
        limiteLine.labelPosition = position
        limiteLine.lineColor = chartData.legend.color
        limiteLine.valueTextColor = chartData.legend.color
        limiteLine.valueFont = Appearance.Cell.Text.accessoryFont
        limiteLine.lineWidth = 2.0
        limiteLine.lineDashLengths = [4.0, 5.0]
        limiteLine.xOffset = 0.0
        limiteLine.yOffset = 0.0
        return limiteLine
    }

}
