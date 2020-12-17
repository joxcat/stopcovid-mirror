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
                
                if !WidgetManager.shared.areStringsAvailableToWidget {
                    Link(destination: WidgetManager.activationDeeplink) {
                        ButtonView(title: "TousAntiCovid")
                    }
                } else if let date = entry.lastStatusReceivedDate {
                    if entry.isSick {
                        SmallInformationsView(date: date,
                                              isAtRisk: false,
                                              isSick: true,
                                              isAtWarningRisk: false)
                    } else if entry.isAtRisk {
                        Link(destination: WidgetManager.moreInformationsDeeplink) {
                            SmallInformationsView(date: date,
                                                  isAtRisk: true,
                                                  isSick: false,
                                                  isAtWarningRisk: false)
                        }
                    } else if entry.isAtWarningRisk {
                        Link(destination: WidgetManager.moreInformationsDeeplink) {
                            SmallInformationsView(date: date,
                                                  isAtRisk: false,
                                                  isSick: false,
                                                  isAtWarningRisk: true)
                        }
                    } else {
                        SmallInformationsView(date: date,
                                              isAtRisk: entry.isAtRisk,
                                              isSick: false,
                                              isAtWarningRisk: false)
                    }
                } else if WidgetManager.shared.isRegistered {
                    SmallInformationsView(date: nil,
                                          isAtRisk: false,
                                          isSick: false,
                                          isAtWarningRisk: false,
                                          didReceiveStatus: false)
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
    static let activatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isAtRisk: false, isSick: false, isAtWarningRisk: false, lastStatusReceivedDate: Date())
    static let activatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: true, isAtRisk: true, isSick: false, isAtWarningRisk: false, lastStatusReceivedDate: Date())
    static let notActivatedNotAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isAtRisk: false, isSick: false, isAtWarningRisk: false, lastStatusReceivedDate: Date())
    static let notActivatedAtRisk: WidgetContent = WidgetContent(isProximityActivated: false, isAtRisk: true, isSick: false, isAtWarningRisk: false, lastStatusReceivedDate: Date())
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
