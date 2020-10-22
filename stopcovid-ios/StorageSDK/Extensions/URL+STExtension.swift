// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URL+STExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 01/06/2020 - for the TousAntiCovid project.
//

import Foundation

extension URL {
    
    mutating func stAddSkipBackupAttribute() throws {
        var values: URLResourceValues = URLResourceValues()
        values.isExcludedFromBackup = true
        try setResourceValues(values)
    }
    
}
