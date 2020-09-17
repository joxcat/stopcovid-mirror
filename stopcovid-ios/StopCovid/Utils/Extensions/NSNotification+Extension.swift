// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSNotification+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 14/04/2020 - for the STOP-COVID project.
//

import UIKit

extension NSNotification.Name {
    
    static var selectTab: NSNotification.Name { NSNotification.Name(rawValue: "selectTab") }
    static var changeAppState: NSNotification.Name { NSNotification.Name(rawValue: "changeAppState") }
    static var didTouchAtRiskNotification: NSNotification.Name = NSNotification.Name(rawValue: "didTouchAtRiskNotification")
    static var didEnterCodeFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "didEnterCodeFromDeeplink")
    
}
