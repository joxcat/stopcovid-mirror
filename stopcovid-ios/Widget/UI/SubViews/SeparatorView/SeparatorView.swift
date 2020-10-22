// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SeparatorView.swift
//  Widget Extension
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import SwiftUI
import WidgetKit

struct SeparatorView: View {
    var body: some View {
        Rectangle()
            .fill(Color("separator"))
            .frame(height: 0.5)
    }
}

struct SeparatorView_Previews: PreviewProvider {
    static var previews: some View {
        SeparatorView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        SeparatorView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
