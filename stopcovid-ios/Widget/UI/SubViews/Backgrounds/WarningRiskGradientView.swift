// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WarningRiskGradientView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct WarningRiskGradientView: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color("gradientStartOrange"), Color("gradientEndOrange")]),
                                 startPoint: .init(x: 0, y: 0.5),
                                 endPoint: .init(x: 1, y: 0.5)))
    }
}

struct WarningRiskGradientView_Previews: PreviewProvider {
    static var previews: some View {
        WarningRiskGradientView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        WarningRiskGradientView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
