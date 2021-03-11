// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIApplication+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIApplication {
    
    var marketingVersion: String {
        Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    var buildNumber: String {
        Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier!
    }
    
    var displayName: String {
        Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), canOpenURL(url) {
            open(url)
        }
    }
    
    func clearBadge() {
        applicationIconBadgeNumber = 0
    }
    
    func killCleanly() {
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { exit(EXIT_SUCCESS) })
    }
    
}
