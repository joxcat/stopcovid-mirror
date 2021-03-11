// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SmallWidgetView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    var entry: WidgetContent
    
    private var activateButtonText: String {
        if WidgetManager.shared.isOnboardingDone {
            return WidgetManager.shared.widgetActivateProximityButtonTitle
        } else {
            return WidgetManager.shared.widgetWelcomeButtonTitle
        }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                SmallStatusView()
                SeparatorView()
                if !WidgetManager.shared.areStringsAvailable() {
                    Link(destination: WidgetManager.activationDeeplink) {
                        ButtonView(title: "AntiCovid")
                    }
                } else if entry.didReceiveStatus {
                    if entry.isSick || entry.currentRiskLevelIsNotZero {
                        Link(destination: WidgetManager.moreInformationsDeeplink) {
                            SmallInformationsView(content: entry)
                        }
                    } else {
                        SmallInformationsView(content: entry)
                    }
                } else if WidgetManager.shared.isRegistered {
                    SmallInformationsView(content: entry)
                } else {
                    Link(destination: WidgetManager.activationDeeplink) {
                        ButtonView(title: activateButtonText)
                    }
                }
            }
        }
    }
}

private struct PreviewData {
    static let activatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 0.0)
    static let activatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 4.0)
    static let notActivatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 0.0)
    static let notActivatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 4.0)
}

struct SmallLightWidgetView_Previews: PreviewProvider {
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

struct SmallDarkWidgetView_Previews: PreviewProvider {
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
