// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  TousAntiCovidWidget.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

@main
struct TousAntiCovidWidget: Widget {
    
    private let kind: String = "TousAntiCovidWidget"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("TousAntiCovid")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    public typealias Entry = WidgetContent
    
    @WidgetUserDefault(key: .isProximityActivated)
    private var isProximityActivated: Bool = false
    
    @WidgetUserDefault(key: .isAtRisk)
    private var isAtRisk: Bool = false
    
    @WidgetUserDefault(key: .isAtWarningRisk)
    private var isAtWarningRisk: Bool = false
    
    @WidgetUserDefault(key: .isSick)
    private var isSick: Bool = false
    
    @WidgetUserDefault(key: .lastStatusReceivedDate)
    private var lastStatusReceivedDate: Date? = nil

    func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> Void) {
        let entry: WidgetContent = WidgetContent(isProximityActivated: isProximityActivated, isAtRisk: isAtRisk, isSick: isSick, isAtWarningRisk: isAtWarningRisk, lastStatusReceivedDate: lastStatusReceivedDate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetContent>) -> Void) {
        let entry: WidgetContent? = WidgetContent(isProximityActivated: isProximityActivated, isAtRisk: isAtRisk, isSick: isSick, isAtWarningRisk: isAtWarningRisk, lastStatusReceivedDate: lastStatusReceivedDate)
        
        var tomorrow: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        tomorrow.addTimeInterval(24.0 * 3600.0)
        
        let timeline = Timeline(entries: [entry].compactMap { $0 }, policy: .after(tomorrow))
        
        completion(timeline)
    }
    
    func placeholder(in context: Context) -> WidgetContent {
        WidgetContent(date: Date(), isProximityActivated: true, isAtRisk: false, isSick: false, isAtWarningRisk: false, lastStatusReceivedDate: Date())
    }
}
