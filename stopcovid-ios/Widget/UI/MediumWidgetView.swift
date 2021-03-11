// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MediumWidgetView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
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
                MediumStatusView()
                SeparatorView()
                if !WidgetManager.shared.areStringsAvailable() {
                    Spacer()
                    Link(destination: WidgetManager.activationDeeplink) {
                        ButtonView(title: "TousAntiCovid")
                    }
                    Spacer()
                } else if entry.didReceiveStatus {
                    if entry.isSick || entry.currentRiskLevelIsNotZero {
                        Link(destination: WidgetManager.moreInformationsDeeplink) {
                            MediumInformationsView(content: entry)
                        }
                    } else {
                        MediumInformationsView(content: entry)
                    }
                } else if WidgetManager.shared.isRegistered {
                    MediumInformationsView(content: entry)
                } else {
                    Spacer()
                    Link(destination: WidgetManager.activationDeeplink) {
                        ButtonView(title: activateButtonText)
                    }
                    Spacer()
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

struct MediumLightWidgetView_Previews: PreviewProvider {
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

struct MediumDarkWidgetView_Previews: PreviewProvider {
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
