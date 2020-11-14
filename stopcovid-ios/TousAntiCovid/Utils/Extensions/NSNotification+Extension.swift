// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSNotification+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 14/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension NSNotification.Name {
    
    static var selectTab: NSNotification.Name { NSNotification.Name(rawValue: "selectTab") }
    static var changeAppState: NSNotification.Name { NSNotification.Name(rawValue: "changeAppState") }
    static var didTouchProximityReactivationNotification: NSNotification.Name = NSNotification.Name(rawValue: "didTouchProximityReactivationNotification")
    static var didEnterCodeFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "didEnterCodeFromDeeplink")
    static var newAttestationFromDeeplink: NSNotification.Name = NSNotification.Name(rawValue: "newAttestationFromDeeplink")
    static var widgetDidRequestRegister: NSNotification.Name = NSNotification.Name(rawValue: "widgetDidRequestRegister")
    static var dismissAllAndShowRecommandations: NSNotification.Name = NSNotification.Name(rawValue: "dismissAllAndShowRecommandations")
    
}
