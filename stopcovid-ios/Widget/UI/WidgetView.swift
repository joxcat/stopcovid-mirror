// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WidgetView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct WidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WidgetContent
    
    var body: some View {
        if family.isSmall {
            SmallWidgetView(entry: entry)
        } else {
            MediumWidgetView(entry: entry)
        }
    }
}

private struct PreviewData {
    static let activatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isAtRisk: false, isSick: false, lastStatusReceivedDate: Date())
    static let activatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isAtRisk: true, isSick: false, lastStatusReceivedDate: Date())
    static let notActivatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isAtRisk: false, isSick: false, lastStatusReceivedDate: Date())
    static let notActivatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isAtRisk: true, isSick: false, lastStatusReceivedDate: Date())
}

struct MainSmallLightWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidgetView(entry: PreviewData.activatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        SmallWidgetView(entry: PreviewData.activatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        SmallWidgetView(entry: PreviewData.notActivatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        SmallWidgetView(entry: PreviewData.notActivatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

struct MainSmallDarkWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidgetView(entry: PreviewData.activatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        SmallWidgetView(entry: PreviewData.activatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        SmallWidgetView(entry: PreviewData.notActivatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        SmallWidgetView(entry: PreviewData.notActivatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
    }
}

struct MainMediumLightWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidgetView(entry: PreviewData.activatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        MediumWidgetView(entry: PreviewData.activatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        MediumWidgetView(entry: PreviewData.notActivatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        MediumWidgetView(entry: PreviewData.notActivatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

struct MainMediumDarkWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidgetView(entry: PreviewData.activatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        MediumWidgetView(entry: PreviewData.activatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        MediumWidgetView(entry: PreviewData.notActivatedAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        MediumWidgetView(entry: PreviewData.notActivatedNotAtRisk)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
    }
}
