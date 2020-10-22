// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Character+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension Character {
    
    var isSimpleEmoji: Bool {
        guard let firstProperty: Unicode.Scalar.Properties = unicodeScalars.first?.properties else { return false }
        return unicodeScalars.count == 1 && (firstProperty.isEmojiPresentation || firstProperty.generalCategory == .otherSymbol)
    }
    var isCombinedIntoEmoji: Bool {
        unicodeScalars.count > 1 && unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }
    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
    
}
