// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIDevice+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the STOP-COVID project.
//


import UIKit

extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier: String = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    var batteryStateString: String {
        switch batteryState {
        case .charging:
            return "Plugged - Charging"
        case .full:
            return "Plugged - Full"
        case .unknown:
            return "Unknown"
        case .unplugged:
            return "Unplugged"
        @unknown default:
            return "-"
        }
    }
    
    var isPlugged: Bool {
        [.charging, .full].contains(batteryState)
    }
    
    var orientationString: String {
        switch orientation {
        case .faceDown:
            return "faceDown"
        case .faceUp:
            return "faceUp"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .unknown:
            return "unknown"
        @unknown default:
            return "-"
        }
    }
    
}
