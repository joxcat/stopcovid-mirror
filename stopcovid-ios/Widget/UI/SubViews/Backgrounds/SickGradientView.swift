// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SickGradientView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct SickGradientView: View {

    var body: some View {
        Rectangle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color("gradientStartBlue"), Color("gradientEndBlue")]),
                                 startPoint: .leading,
                                 endPoint: .trailing))
    }

}

struct SickGradientView_Previews: PreviewProvider {
    static var previews: some View {
        SickGradientView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        SickGradientView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
