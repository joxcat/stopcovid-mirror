// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Array+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import Foundation

extension Array {
    
    func item(at index: Int) -> Element? {
        index < count ? self[index] : nil
    }
    
    func max<T: Comparable>(_ keyPath: KeyPath<Element, T>) -> Element? {
        self.max(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }
    
    func maxValue<T: Comparable>(_ keyPath: KeyPath<Element, T>) -> T? {
        self.max(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })?[keyPath: keyPath]
    }
    
}
