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
                if !WidgetManager.shared.areStringsAvailableToWidget {
                    Spacer()
                    Link(destination: WidgetManager.activationDeeplink) {
                        ButtonView(title: "TousAntiCovid")
                    }
                    Spacer()
                } else if entry.lastStatusReceivedDate != nil {
                    if entry.isSick {
                        Link(destination: WidgetManager.moreInformationsDeeplink) {
                            MediumInformationsView(isAtRisk: false,
                                                   isSick: true)
                        }
                    } else if entry.isAtRisk {
                        Link(destination: WidgetManager.moreInformationsDeeplink) {
                            MediumInformationsView(isAtRisk: true,
                                                   isSick: false)
                        }
                    } else {
                        MediumInformationsView(isAtRisk: false,
                                               isSick: false)
                    }
                } else if WidgetManager.shared.isRegistered {
                    MediumInformationsView(isAtRisk: false,
                                           isSick: false,
                                           didReceiveStatus: false)
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
    static let activatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isAtRisk: false, isSick: false, lastStatusReceivedDate: Date())
    static let activatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isAtRisk: true, isSick: false, lastStatusReceivedDate: Date())
    static let notActivatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isAtRisk: false, isSick: false, lastStatusReceivedDate: Date())
    static let notActivatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isAtRisk: true, isSick: false, lastStatusReceivedDate: Date())
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
