// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  SecKey+RBExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/05/2020 - for the TousAntiCovid project.
//


import UIKit

extension SecKey {
    
    static let derHeader: Data = Data([0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00])
    
    static func fromPublicDer(data: Data) throws -> SecKey {
        guard data.count > derHeader.count else {
            throw NSError.rbLocalizedError(message: "Malformed der key data provided.", code: 0)
        }
        let keyData: Data = data[derHeader.count..<data.count]
        let publicAttributes: CFDictionary = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                              kSecAttrKeyClass as String: kSecAttrKeyClassPublic] as CFDictionary
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, publicAttributes, &error) else {
            throw NSError.rbLocalizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred creating SecKey from provided data", code: 0)
        }
        return secKey
    }
    
    func sec1ToDer() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let keyDataSec1 = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            throw NSError.rbLocalizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred exporting key data", code: 0)
        }
        return SecKey.derHeader + keyDataSec1
    }
    
}
