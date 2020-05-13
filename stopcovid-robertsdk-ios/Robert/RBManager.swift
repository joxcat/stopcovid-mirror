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

final class RBManager {

    static let shared: RBManager = RBManager()
    
    private var server: RBServer!
    private var storage: RBStorage!
    private var bluetooth: RBBluetooth!
    private var ka: Data?
    
    var isRegistered: Bool { storage.isKeyStored() && storage.getLastEpoch() != nil }
    var isProximityActivated: Bool {
        get { storage.isProximityActivated() }
        set { storage.save(proximityActivated: newValue) }
    }
    var isSick: Bool {
        get { storage.isSick() }
        set { storage.save(isSick: newValue) }
    }
    var isAtRisk: Bool? {
        get { storage.isAtRisk() }
        set { storage.save(isAtRisk: newValue) }
    }
    var lastStatusReceivedDate: Date? {
        get { storage.lastStatusReceivedDate() }
        set { storage.saveLastStatusReceivedDate(newValue) }
    }
    var currentEpoch: RBEpoch? { storage.getCurrentEpoch() }
    var localProximityList: [RBLocalProximity] { storage.getLocalProximityList() }
    
    func start(server: RBServer, storage: RBStorage, bluetooth: RBBluetooth) {
        self.server = server
        self.storage = storage
        self.bluetooth = bluetooth
        self.storage.start()
        loadKey()
        if isProximityActivated {
            startProximityDetection()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func startProximityDetection() {
        guard let ka = ka else { return }
        bluetooth.start(helloMessageCreationHandler: { () -> Data in
            if let epoch = self.storage.getCurrentEpoch() {
                let ntpTimestamp: Int = Int(Date().timeIntervalSince1900)
                do {
                    return try RBMessageGenerator.generateHelloMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
                } catch {
                    return Data()
                }
            } else {
                return Data()
            }
        }, ebidExtractionHandler: { helloMessage -> Data in
            RBMessageParser.getEbid(from: helloMessage) ?? Data()
        }, didReceiveProximity: { [weak self] receivedProximity in
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
                                                                    rssiCalibrated: receivedProximity.rssiCalibrated)
            self?.storage.save(localProximity: localProximity)
        })
    }
    
    func stopProximityDetection() {
        bluetooth.stop()
    }
    
    private func loadKey() {
        if let key = storage.getKey() {
            ka = key
        }
    }
    
    private func wipeKey() {
        ka?.wipeData()
    }
    
    @objc private  func applicationWillTerminate() {
        wipeKey()
        storage.stop()
    }
    
}

// MARK: - Server methods -
extension RBManager {
    
    func status(_ completion: @escaping (_ error: Error?) -> ()) {
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = storage.getCurrentEpoch() else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let statusMessage: RBStatusMessage = try RBMessageGenerator.generateStatusMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.status(ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac) { result in
                switch result {
                case let .success(response):
                    do {
                        try self.processStatusResponse(response)
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
    
    func report(token: String, completion: @escaping (_ error: Error?) -> ()) {
        let localHelloMessages: [RBLocalProximity] = storage.getLocalProximityList()
        if localHelloMessages.isEmpty {
            storage.save(isSick: true)
            completion(nil)
        } else {
            server.report(token: token, helloMessages: localHelloMessages) { error in
                if let error = error {
                    completion(error)
                } else {
                    self.storage.save(isSick: true)
                    completion(nil)
                }
            }
        }
    }
    
    func registerIfNeeded(_ completion: @escaping (_ error: Error?) -> ()) {
        if storage.isKeyStored() {
            completion(nil)
        } else {
            register(completion)
        }
    }
    
    func register(_ completion: @escaping (_ error: Error?) -> ()) {
        // TODO: Integrate captcha chosen solution.
        server.register(captcha: "") { result in
            switch result {
            case let .success(response):
                do {
                    try self.processRegisterResponse(response)
                    completion(nil)
                } catch {
                    completion(error)
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    func unregister(_ completion: @escaping (_ error: Error?) -> ()) {
        guard isRegistered else {
            clearAllLocalData()
            completion(nil)
            return
        }
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = storage.getCurrentEpoch() else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Int(Date().timeIntervalSince1900)
            let statusMessage: RBUnregisterMessage = try RBMessageGenerator.generateUnregisterMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.unregister(ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac, completion: { error in
                if let error = error {
                    completion(error)
                } else {
                    self.clearAllLocalData()
                    completion(nil)
                }
            })
        } catch {
            completion(error)
        }
    }
    
    func deleteExposureHistory(_ completion: @escaping (_ error: Error?) -> ()) {
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0))
            return
        }
        guard let epoch = storage.getCurrentEpoch() else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0))
            return
        }
        do {
            let ntpTimestamp: Int = Int(Date().timeIntervalSince1900)
            let statusMessage: RBDeleteExposureHistoryMessage = try RBMessageGenerator.generateDeleteExposureHistoryMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.deleteExposureHistory(ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac, completion: { error in
                if let error = error {
                    completion(error)
                } else {
                    self.clearAllLocalData()
                    completion(nil)
                }
            })
        } catch {
            completion(error)
        }
    }
    
    func clearLocalEpochs() {
        storage.clearLocalEpochs()
    }
    
    func clearLocalProximityList() {
        storage.clearLocalProximityList()
    }
    
    func clearAtRiskAlert() {
        storage.save(isAtRisk: nil)
    }
    
    func clearAllLocalData() {
        storage.clearAll(includingDBKey: false)
        clearKey()
    }
    
    func clearKey() {
        ka?.wipeData()
        ka = nil
    }
    
}

extension RBManager {
    
    private func processRegisterResponse(_ response: RBRegisterResponse) throws {
        guard let data = Data(base64Encoded: response.key) else {
            throw NSError.rbLocalizedError(message: "The provided key is not a valid base64 string", code: 0)
        }
        storage.save(key: data)
        ka = data
        try storage.save(timeStart: response.timeStart)
        if !response.epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: response.epochs)
        }
    }
    
    private func processStatusResponse(_ response: RBStatusResponse) throws {
        storage.save(isAtRisk: response.atRisk)
        storage.save(lastExposureTimeFrame: response.lastExposureTimeFrame)
        if !response.epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: response.epochs)
        }
        lastStatusReceivedDate = Date()
    }
    
}
