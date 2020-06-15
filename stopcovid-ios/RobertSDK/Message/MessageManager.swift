// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RobertMessageManager.swift
//  COVID-19
//
//  Created by Lunabee Studio on 23/04/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

final class RobertMessageManager {
    
    let storage: RobertStorage
    
    init(storage: RobertStorage) {
        self.storage = storage
    }
    
}

// MARK: - Hello Message generation -
extension RobertMessageManager {
    
    func generateCurrentHelloMessage() throws -> Data {
        let epoch: RBEpoch = try storage.getCurrentEpoch()
        let ntpTimestamp: Int = Int(Date().timeIntervalSince1900)
        let key: String = try storage.getKey()
        return generateHelloMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: key)
    }
    
    func generateHelloMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: String) -> Data {
        let message: Data = generateMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: key)
        let mac: Data = generateHelloMessageMac(key: key, message: message)
        return message + mac
    }
    
    private func generateMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: String) -> Data {
        let ecc: Data = Data(base64Encoded: epoch.ecc)!
        let ebid: Data = Data(base64Encoded: epoch.ebid)!
        let time: UInt16 = UInt16(truncating: NSNumber(integerLiteral: ntpTimestamp)).bigEndian
        let data: Data = withUnsafeBytes(of: time) { Data($0) }
        return ecc + ebid + data
    }
    
    private func generateHelloMessageMac(key: String, message: Data) -> Data {
        let totalMessage: Data = Data([RobertConstants.Prefix.c1]) + message
        let parsedKey: String = String(data: Data(base64Encoded: key)!, encoding: .ascii)!
        return totalMessage.hmac(key: parsedKey)[0..<5]
    }

}

// MARK: - Status mac generation -
extension RobertMessageManager {
    
    func generateCurrentStatusMessage() throws -> RBStatusMessage {
        let epoch: RBEpoch = try storage.getCurrentEpoch()
        let ntpTimestamp: Int = Int(Date().timeIntervalSince1900)
        let key: String = try storage.getKey()
        return try generateStatusMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: key)
    }
    
    func generateStatusMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: String) throws -> RBStatusMessage {
        let time: UInt16 = UInt16(truncating: NSNumber(integerLiteral: ntpTimestamp)).bigEndian
        let timeData: Data = withUnsafeBytes(of: time) { Data($0) }
        let mac: Data = try generateStatusMessageMAC(key: key, epoch: epoch, timeData: timeData)
        return RBStatusMessage(ebid: epoch.ebid, time: timeData.base64EncodedString(), mac: mac.base64EncodedString())
    }
    
    private func generateStatusMessageMAC(key: String, epoch: RBEpoch, timeData: Data) throws -> Data {
        guard let ebid = Data(base64Encoded: epoch.ebid) else {
            throw NSError.localizedError(message: "Malformed EBID in epoch", code: 0)
        }
        let totalMessage: Data = Data([RobertConstants.Prefix.c2]) + ebid + timeData
        guard let data = Data(base64Encoded: key), let parsedKey = String(data: data, encoding: .ascii) else {
            throw NSError.localizedError(message: "Malformed key provided for mac calculation", code: 0)
        }
        return totalMessage.hmac(key: parsedKey)
    }

}

// MARK: - Message parsing -
extension RobertMessageManager {
    
    func parseHelloMessage(_ messageData: Data) {
        let eccData: Data = messageData[0..<1]
        let ebidData: Data = messageData[1..<9]
        let timeData: Data = messageData[9..<11]
        let pointer = UnsafePointer(timeData.bytes)
        let time: UInt16 = pointer.withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }.bigEndian
        print("Parsed ecc: \(eccData.base64EncodedString())")
        print("Parsed ebid: \(ebidData.base64EncodedString())")
        print("Parsed time: \(time)")
    }

}
