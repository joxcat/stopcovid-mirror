// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  GroupedMenuEntry.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 06/11/2020 - for the TousAntiCovid project.
//

import UIKit

struct GroupedMenuEntry: Equatable {

    let image: UIImage
    let title: String
    let actionBlock: () -> ()

    static func == (lhs: GroupedMenuEntry, rhs: GroupedMenuEntry) -> Bool {
        lhs.title == rhs.title
    }
    
}
