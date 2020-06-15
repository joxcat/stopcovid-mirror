// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBMessageParser.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import Foundation

final class RBMessageParser {

    static func getEcc(from helloMessage: Data) -> Data? {
        guard helloMessage.count >= 1 else { return nil }
        return helloMessage[0..<1]
    }
    
    static func getEbid(from helloMessage: Data) -> Data? {
        guard helloMessage.count >= 9 else { return nil }
        return helloMessage[1..<9]
    }
    
    static func getTime(from helloMessage: Data) -> UInt16? {
        guard helloMessage.count >= 11 else { return nil }
        let timeData: Data = helloMessage[9..<11]
        let time: UInt16 = timeData.bytes.withUnsafeBufferPointer { $0.baseAddress?.withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }.bigEndian } ?? 0
        return time
    }
    
    static func getMac(from helloMessage: Data) -> Data? {
        guard helloMessage.count >= 16 else { return nil }
        return helloMessage[11..<16]
    }
    
}
