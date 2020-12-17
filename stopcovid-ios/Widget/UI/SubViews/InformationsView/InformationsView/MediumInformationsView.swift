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
    
    var isAtRisk: Bool
    var isSick: Bool
    var isAtWarningRisk: Bool
    var didReceiveStatus: Bool = true
    
    private var statusDateString: String? {
        if didReceiveStatus {
            return WidgetManager.shared.widgetFullTitleDate
        } else {
            return nil
        }
    }
    private var informations: String {
        if !WidgetManager.shared.areStringsAvailableToWidget {
            return "TousAntiCovid"
        } else if isSick {
            return WidgetManager.shared.widgetSickFullTitle
        } else if !didReceiveStatus {
            return WidgetManager.shared.widgetNoStatusInfo
        } else {
            return isAtRisk ? WidgetManager.shared.widgetFullTitleAtRisk : (isAtWarningRisk ? WidgetManager.shared.widgetWarningFullTitle : WidgetManager.shared.widgetFullTitleNoContact)
        }
    }
    
    var body: some View {
        ZStack {
            if isSick {
                SickGradientView()
            } else if isAtRisk {
                AtRiskGradientView()
            } else if isAtWarningRisk {
                WarningRiskGradientView()
            } else if didReceiveStatus && !isSick {
                NoContactGradientView()
            }
            VStack(spacing: 3) {
                if isSick {
                    Spacer()
                    InformationsContentView(title: informations, isAtRisk: false, isSick: isSick, didReceiveStatus: didReceiveStatus)
                    Spacer()
                } else if isAtRisk {
                    InformationsContentView(title: informations, subtitle: statusDateString, isAtRisk: true, isSick: isSick, didReceiveStatus: didReceiveStatus)
                    MoreInformationsView()
                } else {
                    Spacer()
                    InformationsContentView(title: informations, subtitle: statusDateString, isAtRisk: isAtRisk, isSick: isSick, didReceiveStatus: didReceiveStatus)
                    Spacer()
                }
            }
            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        }
    }
}

struct MediumInformationsView_Previews: PreviewProvider {
    static var previews: some View {
        MediumInformationsView(isAtRisk: true, isSick: false, isAtWarningRisk: false)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        MediumInformationsView(isAtRisk: false, isSick: false, isAtWarningRisk: false)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        MediumInformationsView(isAtRisk: true, isSick: false, isAtWarningRisk: false)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        MediumInformationsView(isAtRisk: false, isSick: false, isAtWarningRisk: false)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
    }
}
