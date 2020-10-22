// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIColor+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIColor {
    
    static var isDarkMode: Bool {
        if #available(iOS 12.0, *) {
            return UIApplication.shared.keyWindow?.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hexString: String) {
        let hex: Int = Int(hexString.replacingOccurrences(of: "#", with: ""), radix: 16) ?? 0
        self.init(red: (hex >> 16) & 0xff, green: (hex >> 8) & 0xff, blue: hex & 0xff)
    }
    
    func toHexString() -> String {
        let colorComponents = components()
        let rgb: Int = (Int)(colorComponents.red * 255) << 16 | (Int)(colorComponents.green * 255) << 8 | (Int)(colorComponents.blue * 255) << 0
        return NSString(format: "#%06x", rgb) as String
    }
    
    func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
    
}
