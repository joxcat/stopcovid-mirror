// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Bundle+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 01/06/2020 - for the TousAntiCovid project.
//

import Foundation

extension Bundle {
    
    func fileDataFor(fileName: String, ofType: String) -> Data? {
        guard let filePath = path(forResource: fileName, ofType: "pem") else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        return data
    }
    
}
