// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIFont+Appearance.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIFont {
    
    static func regular(size: CGFloat) -> UIFont {
        FontFamily.SFProText.regular.font(size: size)!
    }
    
    static func medium(size: CGFloat) -> UIFont {
        FontFamily.SFProText.medium.font(size: size)!
    }
    
    static func semibold(size: CGFloat) -> UIFont {
        FontFamily.SFProText.semibold.font(size: size)!
    }
    
    static func bold(size: CGFloat) -> UIFont {
        FontFamily.SFProText.bold.font(size: size)!
    }
    
    static func marianneMedium(size: CGFloat) -> UIFont {
        FontFamily.Marianne.medium.font(size: size)!
    }
    
    static func marianneBold(size: CGFloat) -> UIFont {
        FontFamily.Marianne.bold.font(size: size)!
    }
    
    static func marianneExtraBold(size: CGFloat) -> UIFont {
        FontFamily.Marianne.extraBold.font(size: size)!
    }
    
}
