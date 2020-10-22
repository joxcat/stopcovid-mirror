// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MoreInformationsView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct MoreInformationsView: View {
    private var moreInformations: Text { Text(WidgetManager.shared.widgetMoreInfo) }
    private var questionMark: Image { Image(systemName: "questionmark.circle") }
    
    var body: some View {
        HStack(spacing: 2) {
            questionMark
                .font(SwiftUI.Font(FontFamily.Marianne.bold.font(size: 12)))
                .foregroundColor(.white)
            moreInformations
                .fixedSize(horizontal: false, vertical: true)
                .font(SwiftUI.Font(FontFamily.Marianne.bold.font(size: 12)))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct MoreInformationsView_Previews: PreviewProvider {
    static var previews: some View {
        MoreInformationsView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .padding()
            .background(Color.red)
        MoreInformationsView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .padding()
            .background(Color.red)
        MoreInformationsView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .padding()
            .background(Color.red)
            .environment(\.colorScheme, .dark)
        MoreInformationsView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .padding()
            .background(Color.red)
            .environment(\.colorScheme, .dark)
    }
}
