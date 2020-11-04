// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeepLinkingManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class DeepLinkingManager {

    static let shared: DeepLinkingManager = DeepLinkingManager()
    weak var enterCodeController: EnterCodeController?
    
    func processActivity(_ activity: NSUserActivity) {
        guard activity.activityType == "NSUserActivityTypeBrowsingWeb" else { return }
        guard let url = activity.webpageURL else { return }
        processUrl(url)
    }
    
    func processUrl(_ url: URL) {
        if url.path.hasPrefix("/app/code") {
            processCodeUrl(url)
        } else if url.path.hasPrefix("/app/attestation") {
            processAttestationUrl()
        }
    }
    
    func processCodeUrl(_ url: URL) {
        let code: String = url.path.replacingOccurrences(of: "/app/code/", with: "")
        NotificationCenter.default.post(name: .didEnterCodeFromDeeplink, object: code)
    }
    
    func processAttestationUrl() {
        NotificationCenter.default.post(name: .newAttestationFromDeeplink, object: nil)
    }
    
}
