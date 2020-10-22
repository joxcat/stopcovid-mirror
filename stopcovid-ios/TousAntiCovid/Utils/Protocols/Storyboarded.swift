// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Storyboarded.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol Storyboarded: UIViewController {
    
    static func instantiate(_ storyboardName: String) -> UIViewController
    
}

extension Storyboarded {
    
    static func instantiate(_ storyboardName: String) -> UIViewController {
        let fullName: String = NSStringFromClass(self)
        let className: String = fullName.components(separatedBy: ".")[1]
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: className)
    }
    
}
