// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBMessageGenerator.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import Foundation

final class RBMessageGenerator {

    // MARK: - Hello Message generation -
    static func generateHelloMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: Data) throws -> Data {
        let message: Data = try generateMessage(for: epoch, ntpTimestamp: ntpTimestamp)
        let mac: Data = try generateHelloMessageMac(key: key, message: message)
        return message + mac
    }
    
    private static func generateMessage(for epoch: RBEpoch, ntpTimestamp: Int) throws -> Data {
        guard let ecc = Data(base64Encoded: epoch.ecc) else {
            throw NSError.rbLocalizedError(message: "Malformed ECC in epoch", code: 0)
        }
        guard let ebid = Data(base64Encoded: epoch.ebid) else {
            throw NSError.rbLocalizedError(message: "Malformed EBID in epoch", code: 0)
        }
        let time: UInt16 = UInt16(truncating: NSNumber(integerLiteral: ntpTimestamp)).bigEndian
        let data: Data = withUnsafeBytes(of: time) { Data($0) }
        return ecc + ebid + data
    }
    
    private static func generateHelloMessageMac(key: Data, message: Data) throws -> Data {
        let totalMessage: Data = Data([RBConstants.Prefix.c1]) + message
        return totalMessage.hmac(key: key)[0..<5]
    }
    
    // MARK: - Status mac generation -
    static func generateStatusMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: Data) throws -> RBStatusMessage {
        let time: UInt32 = UInt32(truncating: NSNumber(integerLiteral: ntpTimestamp)).bigEndian
        let timeData: Data = withUnsafeBytes(of: time) { Data($0) }
        let mac: Data = try generateStatusMessageMAC(key: key, epoch: epoch, timeData: timeData)
        return RBStatusMessage(ebid: epoch.ebid, time: timeData.base64EncodedString(), mac: mac.base64EncodedString())
    }
    
    private static func generateStatusMessageMAC(key: Data, epoch: RBEpoch, timeData: Data) throws -> Data {
        guard let ebid = Data(base64Encoded: epoch.ebid) else {
            throw NSError.rbLocalizedError(message: "Malformed EBID in epoch", code: 0)
        }
        let totalMessage: Data = Data([RBConstants.Prefix.c2]) + ebid + timeData
        return totalMessage.hmac(key: key)
    }
    
    // MARK: - Unregister mac generation -
    static func generateUnregisterMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: Data) throws -> RBUnregisterMessage {
        let time: UInt32 = UInt32(truncating: NSNumber(integerLiteral: ntpTimestamp)).bigEndian
        let timeData: Data = withUnsafeBytes(of: time) { Data($0) }
        let mac: Data = try generateUnregisterMessageMAC(key: key, epoch: epoch, timeData: timeData)
        return RBUnregisterMessage(ebid: epoch.ebid, time: timeData.base64EncodedString(), mac: mac.base64EncodedString())
    }
    
    private static func generateUnregisterMessageMAC(key: Data, epoch: RBEpoch, timeData: Data) throws -> Data {
        guard let ebid = Data(base64Encoded: epoch.ebid) else {
            throw NSError.rbLocalizedError(message: "Malformed EBID in epoch", code: 0)
        }
        let totalMessage: Data = Data([RBConstants.Prefix.c3]) + ebid + timeData
        return totalMessage.hmac(key: key)
    }
    
    // MARK: - Delete exposure history mac generation -
    static func generateDeleteExposureHistoryMessage(for epoch: RBEpoch, ntpTimestamp: Int, key: Data) throws -> RBDeleteExposureHistoryMessage {
        let time: UInt32 = UInt32(truncating: NSNumber(integerLiteral: ntpTimestamp)).bigEndian
        let timeData: Data = withUnsafeBytes(of: time) { Data($0) }
        let mac: Data = try generateDeleteExposureHistoryMessageMAC(key: key, epoch: epoch, timeData: timeData)
        return RBDeleteExposureHistoryMessage(ebid: epoch.ebid, time: timeData.base64EncodedString(), mac: mac.base64EncodedString())
    }
    
    private static func generateDeleteExposureHistoryMessageMAC(key: Data, epoch: RBEpoch, timeData: Data) throws -> Data {
        guard let ebid = Data(base64Encoded: epoch.ebid) else {
            throw NSError.rbLocalizedError(message: "Malformed EBID in epoch", code: 0)
        }
        let totalMessage: Data = Data([RBConstants.Prefix.c4]) + ebid + timeData
        return totalMessage.hmac(key: key)
    }
    
}
