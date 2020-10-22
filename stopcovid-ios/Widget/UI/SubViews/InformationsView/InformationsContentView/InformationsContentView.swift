// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InformationsContentView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct InformationsContentView: View {
    @Environment(\.widgetFamily) private var family
    
    var title: String
    var subtitle: String?
    var isAtRisk: Bool
    var isSick: Bool
    var didReceiveStatus: Bool
    
    var body: some View {
        VStack(spacing: isAtRisk ? 3 : 6) {
            if let subtitle = subtitle {
                HStack {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(didReceiveStatus ? .white : Color(.label))
                        .opacity(0.8)
                    Spacer()
                }
            }
            HStack {
                let maxLines: Int = family.isSmall ? (subtitle == nil ? 4 : 2) : 3
                let font: SwiftUI.Font = family.isSmall && subtitle == nil ? SwiftUI.Font(FontFamily.Marianne.bold.font(size: 13)) : SwiftUI.Font(FontFamily.Marianne.bold.font(size: 15))
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(font)
                    .foregroundColor(didReceiveStatus && !isSick ? .white : Color(.label))
                    .lineLimit(maxLines)
                Spacer()
            }
        }
    }
}

struct SmallInformationsContentView_Previews: PreviewProvider {
    static var previews: some View {
        InformationsContentView(title: "Exposition à risque.", subtitle: "10/09 - 13:44", isAtRisk: true, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.red)
        InformationsContentView(title: "Pas de rencontre à risque.", subtitle: "10/09 - 13:44", isAtRisk: false, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        InformationsContentView(title: "Exposition à risque.", subtitle: "10/09 - 13:44", isAtRisk: true, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.red)
            .environment(\.colorScheme, .dark)
        InformationsContentView(title: "Pas de rencontre à risque.", subtitle: "10/09 - 13:44", isAtRisk: false, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
    }
}

struct MediumInformationsContentView_Previews: PreviewProvider {
    static var previews: some View {
        InformationsContentView(title: "Vous avez été exposé à au moins un utilisateur diagnostiqué comme un cas de COVID-19.", subtitle: "Le 10 septembre à 13:44", isAtRisk: true, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.red)
        InformationsContentView(title: "Vous n’avez pas rencontré d’utilisateur diagnostiqué comme un cas de COVID-19.", subtitle: "Le 10 septembre à 13:44", isAtRisk: false, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        InformationsContentView(title: "Vous avez été exposé à au moins un utilisateur diagnostiqué comme un cas de COVID-19.", subtitle: "Le 10 septembre à 13:44", isAtRisk: false, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        InformationsContentView(title: "Vous n’avez pas rencontré d’utilisateur diagnostiqué comme un cas de COVID-19.", subtitle: "Le 10 septembre à 13:44", isAtRisk: true, isSick: false, didReceiveStatus: true)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.red)
            .environment(\.colorScheme, .dark)
    }
}
