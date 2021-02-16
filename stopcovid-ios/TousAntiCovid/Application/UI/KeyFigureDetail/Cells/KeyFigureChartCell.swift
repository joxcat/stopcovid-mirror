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
    @IBOutlet private var chartContainerView: UIView!
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
        guard let chartData = chartDatas.first else { return }
        switch chartData.chartKind {
        case .line:
            setupLineChart(chartDatas: chartDatas)
        case .bars:
            setupBarChart(chartDatas: chartDatas)
        }
    }
    
    override func capture() -> UIImage? {
        sharingImageView.isHidden = true
        let image: UIImage = containerView.screenshot()!
        sharingImageView.isHidden = false
        let captureImageView: UIImageView = UIImageView(image: image)
        captureImageView.frame.size = CGSize(width: image.size.width / UIScreen.main.scale, height: image.size.height / UIScreen.main.scale)
        captureImageView.backgroundColor = Appearance.Cell.cardBackgroundColor
        return captureImageView.screenshot()
    }
    
    @IBAction private func didTouchSharingButton(_ sender: Any) {
        currentAssociatedRow?.selectionActionWithCell?(self)
    }
    
    private func limiteLine(chartData: KeyFigureChartData, position: ChartLimitLine.LabelPosition) -> ChartLimitLine {
        let limiteLine: ChartLimitLine = ChartLimitLine(limit: chartData.limitLineValue ?? 0.0, label: chartData.limitLineLabel?.formattingValueWithThousandsSeparatorIfPossible() ?? "")
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

extension KeyFigureChartCell {
    
    private func setupLineChart(chartDatas: [KeyFigureChartData]) {
        let dataSets: [LineChartDataSet] = chartDatas.map {
            let entries: [ChartDataEntry] = $0.series.map { ChartDataEntry(x: $0.date, y: $0.value) }
            let dataSet: LineChartDataSet = LineChartDataSet(entries: entries)
            dataSet.setupStyle(color: $0.legend.color, entriesCount: entries.count)
            return dataSet
        }
        let lineChartView: LineChartView = LineChartView()
        lineChartView.data = LineChartData(dataSets: dataSets)
        lineChartView.setupStyle()
        lineChartView.leftAxis.setupStyle()
        lineChartView.leftAxis.valueFormatter = ChartsValueFormatter()
        
        let minTodayValue: Double = chartDatas.min { $0.minValue < $1.minValue }?.minValue ?? 0.0
        let maxTodayValue: Double = chartDatas.max { $0.maxValue < $1.maxValue }?.maxValue ?? 0.0
        
        lineChartView.leftAxis.axisMinimum = max(0.0, minTodayValue - (maxTodayValue - minTodayValue) * 0.1)
        
        lineChartView.xAxis.setupStyle()
        lineChartView.xAxis.valueFormatter = ChartsDateFormatter()
        
        chartDatas.forEach {
            guard $0.limitLineValue != nil else { return }
            lineChartView.leftAxis.addLimitLine(limiteLine(chartData: $0, position: .topLeft))
        }
        
        let yAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
           viewPortHandler: lineChartView.viewPortHandler,
           yAxis: lineChartView.leftAxis,
           transformer: lineChartView.getTransformer(forAxis: .left)
        )
        lineChartView.leftYAxisRenderer = yAxisRenderer
        
        chartContainerView.subviews.forEach { $0.removeFromSuperview() }
        chartContainerView.addSubview(lineChartView)
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 0.0).isActive = true
        lineChartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: 0.0).isActive = true
        lineChartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor, constant: 0.0).isActive = true
        lineChartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 0.0).isActive = true
    }
    
    private func setupBarChart(chartDatas: [KeyFigureChartData]) {
        let dataSets: [BarChartDataSet] = chartDatas.map {
            let entries: [BarChartDataEntry] = $0.series.map { BarChartDataEntry(x: $0.date, y: $0.value) }
            let dataSet: BarChartDataSet = BarChartDataSet(entries: entries)
            dataSet.setupStyle(color: $0.legend.color, entriesCount: entries.count)
            return dataSet
        }
        let barChartView: BarChartView = BarChartView()
        let data: BarChartData = BarChartData(dataSets: dataSets)
        data.setupStyle(entriesCount: dataSets.first?.entries.count ?? 0)
        barChartView.data = data
        barChartView.setupStyle()
        barChartView.leftAxis.setupStyle()
        barChartView.leftAxis.valueFormatter = ChartsValueFormatter()
        
        barChartView.leftAxis.axisMinimum = 0.0
        barChartView.xAxis.setupStyle()
        barChartView.xAxis.valueFormatter = ChartsDateFormatter()
        
        chartDatas.forEach {
            guard $0.limitLineValue != nil else { return }
            barChartView.leftAxis.addLimitLine(limiteLine(chartData: $0, position: .topLeft))
        }
        
        let yAxisRenderer: YAxisCustomRenderer = YAxisCustomRenderer(
           viewPortHandler: barChartView.viewPortHandler,
           yAxis: barChartView.leftAxis,
           transformer: barChartView.getTransformer(forAxis: .left)
        )
        barChartView.leftYAxisRenderer = yAxisRenderer
        barChartView.fitBars = true
        
        chartContainerView.subviews.forEach { $0.removeFromSuperview() }
        chartContainerView.addSubview(barChartView)
        barChartView.translatesAutoresizingMaskIntoConstraints = false
        barChartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor, constant: 0.0).isActive = true
        barChartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor, constant: 0.0).isActive = true
        barChartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor, constant: 0.0).isActive = true
        barChartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 0.0).isActive = true
    }
    
}
