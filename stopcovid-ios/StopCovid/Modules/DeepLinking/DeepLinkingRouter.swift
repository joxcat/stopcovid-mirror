// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeepLinkingRouter.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the STOP-COVID project.
//

import UIKit

final class DeepLinkingRouter {

    static func processUrl(_ url: URL) {
        let code: String = url.path.replacingOccurrences(of: "/", with: "")
        NotificationCenter.default.post(name: .didEnterCodeFromDeeplink, object: code)
    }
    
}
