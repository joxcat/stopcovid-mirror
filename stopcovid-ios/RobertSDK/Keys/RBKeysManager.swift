// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBKeysManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/05/2020 - for the TousAntiCovid project.
//


import Foundation

final class RBKeysManager {
    
    static func generateKeys() throws -> RBECKeys {
        var publicKeySec: SecKey?
        var privateKeySec: SecKey?
        let keyAttributes: CFDictionary = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                           kSecAttrKeySizeInBits as String: 256] as CFDictionary
        SecKeyGeneratePair(keyAttributes, &publicKeySec, &privateKeySec)
        guard let publicKey = publicKeySec, let privateKey = privateKeySec else {
            throw NSError.rbLocalizedError(message: "Impossible to generate a key pair", code: 0)
        }
        let publicKeyBase64: String = try publicKey.sec1ToDer().base64EncodedString()
        return RBECKeys(publicKeyBase64: publicKeyBase64, privateKey: privateKey)
    }
    
    static func generateSecret(keys: RBECKeys, serverPublicKey: Data) throws -> RBCryptoKeys {
        let publicSecKey: SecKey = try SecKey.fromPublicDer(data: serverPublicKey)
        var error: Unmanaged<CFError>?
        guard let sharedSecretData = SecKeyCopyKeyExchangeResult(keys.privateKey, .ecdhKeyExchangeStandard, publicSecKey, [:] as CFDictionary, &error) as Data? else {
            throw NSError.rbLocalizedError(message: (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "An unknown error occurred creating shared secret", code: 0)
        }
        let ka: Data = try generateKA(with: sharedSecretData)
        let kea: Data = try generateKEA(with: sharedSecretData)
        return RBCryptoKeys(ka: ka, kea: kea)
    }
    
    private static func generateKA(with sharedSecret: Data) throws -> Data {
        Data([109, 97, 99]).hmac(key: sharedSecret)
    }
    
    private static func generateKEA(with sharedSecret: Data) throws -> Data {
        Data([116, 117, 112, 108, 101, 115]).hmac(key: sharedSecret)
    }
    
}
