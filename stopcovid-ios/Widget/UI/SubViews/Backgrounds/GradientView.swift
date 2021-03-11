// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  GradientView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct GradientView: View {

    var body: some View {
        Rectangle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color(UIColor(hexString: WidgetManager.shared.widgetGradientStartColor)), Color(UIColor(hexString: WidgetManager.shared.widgetGradientEndColor))]),
                                 startPoint: .init(x: 0, y: 0.5),
                                 endPoint: .init(x: 1, y: 0.5)))
    }
}

struct AtRiskGradientView_Previews: PreviewProvider {
    static var previews: some View {
        GradientView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        GradientView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
