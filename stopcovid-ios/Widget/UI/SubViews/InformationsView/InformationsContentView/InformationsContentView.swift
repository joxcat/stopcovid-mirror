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
    var content: WidgetContent

    var body: some View {
        VStack(spacing: content.currentRiskLevelIsNotZero ? 3 : 6) {
            if let subtitle = subtitle {
                HStack {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(content.didReceiveStatus ? .white : Color(.label))
                        .opacity(0.8)
                    Spacer()
                }
            }
            HStack {
                let maxLines: Int = family.isSmall ? (subtitle == nil ? 4 : 3) : 3
                let font: SwiftUI.Font = family.isSmall && subtitle == nil ? SwiftUI.Font(FontFamily.Marianne.bold.font(size: 13)) : SwiftUI.Font(FontFamily.Marianne.bold.font(size: 15))
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(font)
                    .foregroundColor(content.didReceiveStatus || content.isSick ? .white : Color(.label))
                    .lineLimit(maxLines)
                Spacer()
            }
        }
    }
}

struct SmallInformationsContentView_Previews: PreviewProvider {
    static let content: WidgetContent = WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 0.0)
    static var previews: some View {
        InformationsContentView(title: "Exposition à risque.", subtitle: "10/09 - 13:44", content: content)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .background(Color.red)
    }
}

struct MediumInformationsContentView_Previews: PreviewProvider {
    static let content: WidgetContent = WidgetContent(isProximityActivated: true, isSick: false, lastStatusReceivedDate: Date(), currentRiskLevel: 0.0)
    static var previews: some View {
        InformationsContentView(title: "Vous avez été exposé à au moins un utilisateur diagnostiqué comme un cas de COVID-19.", subtitle: "Le 10 septembre à 13:44", content: content)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.red)
    }
}
