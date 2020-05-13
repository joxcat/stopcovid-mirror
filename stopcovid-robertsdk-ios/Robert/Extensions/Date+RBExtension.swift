// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Date+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import Foundation

extension Date {
    
    var timeIntervalSince1900: Int {
        return Int(timeIntervalSince1970) + 2208988800
    }
    
    init(timeIntervalSince1900: Int) {
        self.init(timeIntervalSince1970: Double(timeIntervalSince1900 - 2208988800))
    }
    
}
