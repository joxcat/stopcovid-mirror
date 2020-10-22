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
    
    var date: Date?
    var isAtRisk: Bool
    var isSick: Bool
    var didReceiveStatus: Bool = true
    
    private var statusDateString: String? {
        if WidgetManager.shared.areStringsAvailableToWidget {
            if didReceiveStatus {
                let date: String
                let time: String
                let formatter: DateFormatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("ddMM")
                date = formatter.string(from:self.date ?? Date())
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                time = formatter.string(from: self.date ?? Date())
                return "\(date) - \(time)"
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    private var informations: String {
        if !WidgetManager.shared.areStringsAvailableToWidget {
            return "AntiCovid"
        } else if isSick {
            return WidgetManager.shared.widgetSickSmallTitle
        } else if !didReceiveStatus {
            return WidgetManager.shared.widgetNoStatusInfo
        } else {
            return isAtRisk ? WidgetManager.shared.widgetSmallTitleAtRisk : WidgetManager.shared.widgetSmallTitleNoContact
        }
    }
    
    var body: some View {
        ZStack {
            if isAtRisk {
                AtRiskGradientView()
            } else if didReceiveStatus && !isSick {
                NoContactGradientView()
            }
            VStack(spacing: 4) {
                if isSick { Spacer() }
                InformationsContentView(title: informations, subtitle: isSick ? nil : statusDateString, isAtRisk: isAtRisk, isSick: isSick, didReceiveStatus: didReceiveStatus)
                if isAtRisk { MoreInformationsView() }
                if !isAtRisk { Spacer() }
                Spacer()
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 0, trailing: 12))
        }
    }
}

struct SmallInformationsView_Previews: PreviewProvider {
    static var previews: some View {
        SmallInformationsView(date: Date(), isAtRisk: true, isSick: false)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        SmallInformationsView(date: Date(), isAtRisk: false, isSick: false)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        SmallInformationsView(date: Date(), isAtRisk: true, isSick: false)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        SmallInformationsView(date: Date(), isAtRisk: false, isSick: false)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
    }
}
