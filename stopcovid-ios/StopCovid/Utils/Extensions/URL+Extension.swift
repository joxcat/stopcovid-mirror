// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URL+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 12/04/2020 - for the STOP-COVID project.
//

import UIKit

extension URL {
    
    func openInSafari() {
        if UIApplication.shared.canOpenURL(self) {
            UIApplication.shared.open(self)
        }
    }
    
    func share(from controller: UIViewController, fromButton: UIButton? = nil) {
        let activityController: UIActivityViewController = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        if let button = fromButton {
            activityController.popoverPresentationController?.setSourceButton(button)
        }
        controller.present(activityController, animated: true, completion: nil)
    }
    
    mutating func addSkipBackupAttribute() throws {
        var values: URLResourceValues = URLResourceValues()
        values.isExcludedFromBackup = true
        try setResourceValues(values)
    }
    
}
