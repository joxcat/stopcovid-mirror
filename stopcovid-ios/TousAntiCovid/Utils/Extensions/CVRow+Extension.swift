// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVRow+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension CVRow {
    
    static func titleRow(title: String?, willDisplay: ((_ cell: CVTableViewCell) -> ())?) -> CVRow {
        return CVRow(title: title,
                     xibName: .titleCell,
                     theme: CVRow.Theme(topInset: 10.0,
                                        bottomInset: 10.0,
                                        textAlignment: .natural,
                                        titleFont: { Appearance.Controller.titleFont },
                                        separatorLeftInset: nil),
                     willDisplay: willDisplay)
    }
    
}
