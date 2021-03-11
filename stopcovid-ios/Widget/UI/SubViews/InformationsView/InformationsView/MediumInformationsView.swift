// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MediumInformationsView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct MediumInformationsView: View {
    
    var content: WidgetContent

    private var statusDateString: String? {
        guard WidgetManager.shared.areStringsAvailable() else { return nil }
        guard content.didReceiveStatus else { return nil }
        return WidgetManager.shared.widgetFullTitleDate
    }

    private var informations: String {
        if !WidgetManager.shared.areStringsAvailable() {
            return "TousAntiCovid"
        } else if content.isSick {
            return WidgetManager.shared.widgetSickFullTitle
        } else if !content.didReceiveStatus {
            return WidgetManager.shared.widgetNoStatusInfo
        } else {
            return  WidgetManager.shared.widgetFullTitle
        }
    }
    
    var body: some View {
        ZStack {
            if content.isSick {
                SickGradientView()
            } else if content.didReceiveStatus {
                GradientView()
            }
            VStack(spacing: 3) {
                if content.isSick {
                    Spacer()
                    InformationsContentView(title: informations, content: content)
                    Spacer()
                } else if content.currentRiskLevelIsNotZero {
                    InformationsContentView(title: informations, subtitle: statusDateString, content: content)
                    MoreInformationsView()
                } else {
                    Spacer()
                    InformationsContentView(title: informations, subtitle: statusDateString, content: content)
                    Spacer()
                }
            }
            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        }
    }
}

struct MediumInformationsView_Previews: PreviewProvider {
    static let content: WidgetContent = WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 0.0)
    static var previews: some View {
        MediumInformationsView(content: content)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
