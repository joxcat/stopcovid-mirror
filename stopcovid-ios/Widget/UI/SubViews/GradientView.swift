//
//  AtRiskGradientView.swift
//  Widget Plus Extension
//
//  Created by Alexandre Cools on 11/09/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import SwiftUI

struct AtRiskGradientView: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color("gradientStartRed"), Color("gradientEndRed")]),
                                 startPoint: .init(x: 0, y: 1),
                                 endPoint: .init(x: 1, y: 0)))
    }
}
