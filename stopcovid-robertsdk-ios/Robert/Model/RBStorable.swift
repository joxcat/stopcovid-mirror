// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBStorable.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import UIKit

protocol RBStorable: Codable {
    
    static func from(data: Data) throws -> Self
    func toData() throws -> Data
    
}

extension RBStorable {
    
    static func from(data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
    
    func toData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
}
