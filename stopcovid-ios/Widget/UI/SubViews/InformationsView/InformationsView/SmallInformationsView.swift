// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SmallInformationsView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct SmallInformationsView: View {
    
    var content: WidgetContent
    
    private var statusDateString: String? {
        guard WidgetManager.shared.areStringsAvailable() else { return nil }
        guard let lastStatusReceivedDate = content.lastStatusReceivedDate else { return nil }
        let date: String
        let time: String
        let formatter: DateFormatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("ddMM")
        date = formatter.string(from: lastStatusReceivedDate)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        time = formatter.string(from: lastStatusReceivedDate)
        return "\(date) - \(time)"
    }
    private var informations: String {
        if !WidgetManager.shared.areStringsAvailable() {
            return "AntiCovid"
        } else if content.isSick {
            return WidgetManager.shared.widgetSickSmallTitle
        } else if !content.didReceiveStatus {
            return WidgetManager.shared.widgetNoStatusInfo
        } else {
            return WidgetManager.shared.widgetSmallTitle
        }
    }
    
    var body: some View {
        ZStack {
            if content.isSick {
                SickGradientView()
            } else if content.didReceiveStatus {
                GradientView()
            }
            VStack(spacing: 4) {
                if content.isSick { Spacer() }
                InformationsContentView(title: informations, subtitle: content.isSick ? nil : statusDateString, content: content)
                if content.currentRiskLevelIsNotZero { MoreInformationsView() }
                if !content.currentRiskLevelIsNotZero { Spacer() }
                Spacer()
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
        }
    }
}

struct SmallInformationsView_Previews: PreviewProvider {
    static let content: WidgetContent = WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 0.0)
    static var previews: some View {
        SmallInformationsView(content: content)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
