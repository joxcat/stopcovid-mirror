// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Data+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import UIKit
import CommonCrypto

extension Data {

    var bytes: [UInt8] { [UInt8](self) }

    func hmac(key: Data) -> Data {
        let string: UnsafePointer<UInt8> = (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count)
        let stringLength = self.count
        let keyString: [CUnsignedChar] = [UInt8](key)
        let keyLength: Int = key.bytes.count
        var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyString, keyLength, string, stringLength, &result)
        return Data(result)
    }
    
    mutating func wipeData() {
        guard let range = Range(NSMakeRange(0, count)) else { return }
        resetBytes(in: range)
    }

}
