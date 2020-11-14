// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFiguresConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import Foundation

enum KeyFiguresConstant {
    
    #if DEBUG
    static let jsonUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/json/version-\(Constant.Server.jsonVersion)/InfoCenter-Plus/key-figures.json")!
    #elseif PROD
    static let jsonUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/infos/key-figures.json")!
    #elseif PROD_PLUS
    static let jsonUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/infos-plus/key-figures.json")!
    #endif
    
}
