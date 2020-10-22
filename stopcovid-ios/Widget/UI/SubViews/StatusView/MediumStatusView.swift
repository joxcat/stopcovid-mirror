// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MediumStatusView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct MediumStatusView: View {
    var statusText: String { "TousAntiCovid" }
    var statusColor: Color { Color(.label) }
    
    var body: some View {
        HStack(spacing: 4) {
            Image("icon_tousAntiCovid")
                .resizable()
                .frame(width: 32, height: 32)
            HStack(spacing: 4) {
                HStack(spacing: 0) {
                    Text(statusText)
                        .font(SwiftUI.Font(FontFamily.Marianne.bold.font(size: 17)))
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
}

struct MediumStatusView_Previews: PreviewProvider {
    static var previews: some View {
        MediumStatusView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        MediumStatusView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        MediumStatusView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
        MediumStatusView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .background(Color.black)
            .environment(\.colorScheme, .dark)
    }
}
