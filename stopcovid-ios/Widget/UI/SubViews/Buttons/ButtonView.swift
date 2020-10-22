// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ButtonView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct ButtonView: View {
    var title: String
    
    var body: some View {
        Button(action: {},
               label: {
                HStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: 17))
                        .fontWeight(.medium)
                        .kerning(-0.4)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                        .foregroundColor(Color("inversedLabel"))
                    Spacer()
                }
                .padding(EdgeInsets(top: 16, leading: 4, bottom: 16, trailing: 4))
                .background(Color("buttonBackground"))
                .cornerRadius(8)
               })
            .padding()
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(title: "J'active TousAntiCovid")
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        ButtonView(title: "J'active TousAntiCovid")
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
