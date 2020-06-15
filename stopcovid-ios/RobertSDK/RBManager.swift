// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import UIKit
import SwCrypt

public final class RBManager {

    public static let shared: RBManager = RBManager()
    
    private var server: RBServer!
    private var storage: RBStorage!
    private var bluetooth: RBBluetooth!
    private var ka: Data? { storage.getKa() }
    private var kea: Data? { storage.getKea() }
    
    public var isRegistered: Bool { storage.areKeysStored() && storage.getLastEpoch() != nil }
    public var isProximityActivated: Bool {
        get { storage.isProximityActivated() }
        set { storage.save(proximityActivated: newValue) }
    }
    public var isSick: Bool {
        get { storage.isSick() }
        set { storage.save(isSick: newValue) }
    }
    public var isAtRisk: Bool? {
        get { storage.isAtRisk() }
        set {
            storage.save(isAtRisk: newValue)
            isAtRiskDidChangeHandler?(newValue)
        }
    }
    public var lastStatusReceivedDate: Date? {
        get { storage.lastStatusReceivedDate() }
        set { storage.saveLastStatusReceivedDate(newValue) }
    }
    public var lastExposureTimeFrame: Int? {
        get { storage.lastExposureTimeFrame() }
        set { storage.save(lastExposureTimeFrame: newValue) }
    }
    public var epochsCount: Int { storage.epochsCount() }
    public var currentEpoch: RBEpoch? { storage.getCurrentEpoch(defaultingToLast: false) }
    public var currentEpochOrLast: RBEpoch? { storage.getCurrentEpoch(defaultingToLast: true) }
    public var localProximityList: [RBLocalProximity] { storage.getLocalProximityList() }
    
    public var proximitiesRetentionDurationInDays: Int?
    public var preSymptomsSpan: Int?
    
    private var isAtRiskDidChangeHandler: ((_ isAtRisk: Bool?) -> ())?
    private var didStopProximityDueToLackOfEpochsHandler: (() -> ())?
    
    // Prevent any other instantiations.
    private init() {}
    
    public func start(isFirstInstall: Bool = false, server: RBServer, storage: RBStorage, bluetooth: RBBluetooth, restartProximityIfPossible: Bool = true, isAtRiskDidChangeHandler: @escaping (_ isAtRisk: Bool?) -> (), didStopProximityDueToLackOfEpochsHandler: @escaping () -> ()) {
        self.server = server
        self.storage = storage
        self.bluetooth = bluetooth
        self.isAtRiskDidChangeHandler = isAtRiskDidChangeHandler
        self.didStopProximityDueToLackOfEpochsHandler = didStopProximityDueToLackOfEpochsHandler
        if isFirstInstall {
            self.storage.clearAll(includingDBKey: true)
        }
        self.storage.start()
        if isProximityActivated && restartProximityIfPossible && !isFirstInstall {
            startProximityDetection()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    public func startProximityDetection() {
        guard let ka = ka else { return }
        bluetooth.start(helloMessageCreationHandler: { completion in
            DispatchQueue.main.async {
                if let epoch = self.currentEpoch {
                    let ntpTimestamp: Int = Date().timeIntervalSince1900
                    do {
                        let data = try RBMessageGenerator.generateHelloMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
                        completion(data)
                    } catch {
                        completion(nil)
                    }
                } else {
                    self.isProximityActivated = false
                    self.stopProximityDetection()
                    self.didStopProximityDueToLackOfEpochsHandler?()
                    completion(nil)
                }
            }
        }, ebidExtractionHandler: { helloMessage -> Data in
            RBMessageParser.getEbid(from: helloMessage) ?? Data()
        }, didReceiveProximity: { [weak self] receivedProximity in
            DispatchQueue.main.async {
                let eccString: String? = RBMessageParser.getEcc(from: receivedProximity.data)?.base64EncodedString()
                let ebidString: String? = RBMessageParser.getEbid(from: receivedProximity.data)?.base64EncodedString()
                let timeInt: UInt16? = RBMessageParser.getTime(from: receivedProximity.data)
                let macString: String? = RBMessageParser.getMac(from: receivedProximity.data)?.base64EncodedString()
                guard let ecc = eccString, let ebid = ebidString, let time = timeInt, let mac = macString else {
                    return
                }
                let localProximity: RBLocalProximity = RBLocalProximity(ecc: ecc,
                                                                        ebid: ebid,
                                                                        mac: mac,
                                                                        timeFromHelloMessage: time,
                                                                        timeCollectedOnDevice: receivedProximity.timeCollectedOnDevice,
                                                                        rssiRaw: receivedProximity.rssiRaw,
                                                                        rssiCalibrated: receivedProximity.rssiCalibrated,
                                                                        tx: receivedProximity.tx)
                self?.storage.save(localProximity: localProximity)
            }
        })
    }
    
    public func stopProximityDetection() {
        bluetooth.stop()
    }
    
    @objc private  func applicationWillTerminate() {
        storage.stop()
    }
    
}

// MARK: - Server methods -
extension RBManager {
    
    public func status(_ completion: @escaping (_ error: Error?) -> ()) {
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = currentEpochOrLast else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let statusMessage: RBStatusMessage = try RBMessageGenerator.generateStatusMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.status(epochId: statusMessage.epochId, ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac) { result in
                switch result {
                case let .success(response):
                    do {
                        try self.processStatusResponse(response)
                        self.clearOldLocalProximities()
                        completion(nil)
                    } catch {
                        completion(error)
                    }
                case let .failure(error):
                    completion(error)
                }
            }
        } catch {
            completion(error)
        }
    }
    
    public func report(code: String, symptomsOrigin: Date?, completion: @escaping (_ error: Error?) -> ()) {
        let origin: Date = symptomsOrigin?.rbDateByAddingDays(-(preSymptomsSpan ?? 0)) ?? .distantPast
        let localHelloMessages: [RBLocalProximity] = storage.getLocalProximityList(from: origin, to: Date())
        server.report(code: code, helloMessages: localHelloMessages) { error in
            if let error = error {
                completion(error)
            } else {
                self.clearLocalProximityList()
                self.isSick = true
                completion(nil)
            }
        }
    }
    
    public func registerIfNeeded(token: String, completion: @escaping (_ error: Error?) -> ()) {
        if isRegistered {
            completion(nil)
        } else {
            register(token: token, completion: completion)
        }
    }
    
    public func register(token: String, completion: @escaping (_ error: Error?) -> ()) {
        guard let keys: RBECKeys = try? RBKeysManager.generateKeys() else {
            completion(NSError.rbLocalizedError(message: "Impossible to set keys up.", code: 0))
            return
        }
        server.register(token: token, publicKey: keys.publicKeyBase64) { result in
            switch result {
            case let .success(response):
                do {
                    try self.processRegisterResponse(response, keys: keys)
                    completion(nil)
                } catch {
                    completion(error)
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    public func unregister(_ completion: @escaping (_ error: Error?) -> ()) {
        guard isRegistered else {
            isProximityActivated = false
            stopProximityDetection()
            clearAllLocalData()
            completion(nil)
            return
        }
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = currentEpochOrLast else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let unregisterMessage: RBUnregisterMessage = try RBMessageGenerator.generateUnregisterMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.unregister(epochId: unregisterMessage.epochId, ebid: unregisterMessage.ebid, time: unregisterMessage.time, mac: unregisterMessage.mac, completion: { error in
                if let error = error {
                    completion(error)
                } else {
                    self.isProximityActivated = false
                    self.stopProximityDetection()
                    self.clearAllLocalData()
                    completion(nil)
                }
            })
        } catch {
            completion(error)
        }
    }
    
    public func deleteExposureHistory(_ completion: @escaping (_ error: Error?) -> ()) {
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = currentEpochOrLast else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let deleteExposureHistoryMessage: RBDeleteExposureHistoryMessage = try RBMessageGenerator.generateDeleteExposureHistoryMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.deleteExposureHistory(epochId: deleteExposureHistoryMessage.epochId, ebid: deleteExposureHistoryMessage.ebid, time: deleteExposureHistoryMessage.time, mac: deleteExposureHistoryMessage.mac, completion: { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            })
        } catch {
            completion(error)
        }
    }
    
    public func clearLocalEpochs() {
        storage.clearLocalEpochs()
    }
    
    public func clearLocalProximityList() {
        storage.clearLocalProximityList()
    }
    
    public func clearAtRiskAlert() {
        storage.save(isAtRisk: nil)
    }
    
    public func clearAllLocalData() {
        storage.clearAll(includingDBKey: false)
    }
    
    private func clearOldLocalProximities() {
        guard let retentionDuration = proximitiesRetentionDurationInDays else { return }
        storage.clearProximityList(before: Date().rbDateByAddingDays(-retentionDuration))
    }
    
}

extension RBManager {
    
    private func processRegisterResponse(_ response: RBRegisterResponse, keys: RBECKeys) throws {
        let cryptoKeys: RBCryptoKeys = try RBKeysManager.generateSecret(keys: keys, serverPublicKey: server.publicKey)
        storage.save(ka: cryptoKeys.ka)
        storage.save(kea: cryptoKeys.kea)
        
        let epochs: [RBEpoch] = try decrypt(tuples: response.tuples)
        try storage.save(timeStart: response.timeStart)
        if !epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: epochs)
        }
        lastStatusReceivedDate = Date()
    }
    
    private func processStatusResponse(_ response: RBStatusResponse) throws {
        let epochs: [RBEpoch] = try decrypt(tuples: response.tuples)
        storage.save(isAtRisk: response.atRisk)
        storage.save(lastExposureTimeFrame: response.lastExposureTimeFrame)
        if !epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: epochs)
        }
        lastStatusReceivedDate = Date()
    }
    
    private func decrypt(tuples: String) throws -> [RBEpoch] {
        let tuplesData: Data = Data(base64Encoded: tuples)!
        let iv: Data = Data(tuplesData[0..<12])
        let cypher: Data = Data(tuplesData[12..<tuplesData.count])
        let result: Data = try CC.cryptAuth(.decrypt, blockMode: .gcm, algorithm: .aes, data: cypher, aData: Data(), key: kea!, iv: iv, tagLength: 16)
        let epochs: [RBEpoch] = try JSONDecoder().decode([RBEpoch].self, from: result)
        return epochs
    }
    
}
