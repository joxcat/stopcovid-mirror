// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NSNotification+STExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 14/04/2020 - for the TousAntiCovid project.
//

import UIKit

public extension NSNotification.Name {
    
    static var statusDataDidChange: NSNotification.Name = NSNotification.Name(rawValue: "statusDataDidChange")
    static var localProximityDataDidChange: NSNotification.Name = NSNotification.Name(rawValue: "localProximityDataDidChange")
    static var attestationDataDidChange: NSNotification.Name = NSNotification.Name(rawValue: "attestationDataDidChange")
    static var venueQrCodeDataDidChange: NSNotification.Name = NSNotification.Name(rawValue: "venueQrCodeDataDidChange")
}
