// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the TousAntiCovid project.
//

import UIKit
import SwCrypt

public final class RBManager {

    public static let shared: RBManager = RBManager()
    
    private var server: RBServer!
    private var storage: RBStorage!
    private var bluetooth: RBBluetooth!
    private var filter: RBFiltering!
    
    private var ka: Data? { storage.getKa() }
    private var kea: Data? { storage.getKea() }
    
    public var isInitialized: Bool { storage != nil }
    public var isRegistered: Bool { storage.areKeysStored() && storage.getLastEpoch() != nil }
    public var isProximityActivated: Bool {
        get { storage.isProximityActivated() }
        set { storage.save(proximityActivated: newValue) }
    }
    public var canReactivateProximity: Bool {
        guard let reportDate = storage.reportDate() else { return true }
        return Date().timeIntervalSince1970 - reportDate.timeIntervalSince1970 > RBConstants.proximityReactivationBlockingDelay
    }
    public var isSick: Bool {
        get { storage.isSick() }
        set { storage.save(isSick: newValue) }
    }
    public var pushToken: String? {
        get { storage.pushToken() }
        set { storage.save(pushToken: newValue) }
    }
    
    public var currentStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { storage.currentStatusRiskLevel() }
        set { storage.saveCurrentStatusRiskLevel(newValue) }
    }
    public var lastRobertStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { storage.lastRobertStatusRiskLevel() }
        set { storage.saveLastRobertStatusRiskLevel(newValue) }
    }
    public var lastWarningStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { storage.lastWarningStatusRiskLevel() }
        set { storage.saveLastWarningStatusRiskLevel(newValue) }
    }
    public var declarationToken: String? {
        get { storage.declarationToken() }
        set { storage.saveDeclarationToken(newValue) }
    }
    
    public var lastStatusRequestDate: Date? {
        get { storage.lastStatusRequestDate() }
        set { storage.saveLastStatusRequestDate(newValue) }
    }
    public var lastStatusReceivedDate: Date? {
        get { storage.lastStatusReceivedDate() }
        set { storage.saveLastStatusReceivedDate(newValue) }
    }
    public var lastStatusErrorDate: Date? {
        get { storage.lastStatusErrorDate() }
        set { storage.saveLastStatusErrorDate(newValue) }
    }
    public var lastRiskReceivedDate: Date? {
        get { storage.lastRiskReceivedDate() }
        set { storage.saveLastRiskReceivedDate(newValue) }
    }

    public var reportDate: Date? {
        get { storage.reportDate() }
        set { storage.saveReportDate(newValue) }
    }
    public var reportDataOriginDate: Date? {
        get { storage.reportDataOriginDate() }
        set { storage.saveReportDataOriginDate(newValue) }
    }
    public var reportSymptomsStartDate: Date? {
        get { storage.reportSymptomsStartDate() }
        set { storage.saveReportSymptomsStartDate(newValue) }
    }
    public var reportPositiveTestDate: Date? {
        get { storage.reportPositiveTestDate() }
        set { storage.saveReportPositiveTestDate(newValue) }
    }
    public var reportToken: String? {
        get { storage.reportToken() }
        set { storage.saveReportToken(newValue) }
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
    public var positiveSampleSpan: Int?
    
    private var didStopProximityDueToLackOfEpochsHandler: (() -> ())?
    private var didReceiveProximityHandler: (() -> ())?
    private var didSaveProximity: ((_ receivedProximity: RBReceivedProximity) -> ())?

    
    // Prevent any other instantiations.
    private init() {}
    
    public func start(isFirstInstall: Bool = false, server: RBServer, storage: RBStorage, bluetooth: RBBluetooth, filter: RBFiltering, restartProximityIfPossible: Bool = true, didStopProximityDueToLackOfEpochsHandler: @escaping () -> (), didReceiveProximityHandler: @escaping () -> (), didSaveProximity: ((_ receivedProximity: RBReceivedProximity) -> ())? = nil) {
        self.server = server
        self.storage = storage
        self.bluetooth = bluetooth
        self.filter = filter
        self.didStopProximityDueToLackOfEpochsHandler = didStopProximityDueToLackOfEpochsHandler
        self.didReceiveProximityHandler = didReceiveProximityHandler
        self.didSaveProximity = didSaveProximity
        if isFirstInstall {
            self.storage.clearAll(includingDBKey: true)
        }
        self.storage.start()
        if isProximityActivated && restartProximityIfPossible && !isFirstInstall {
            if isRegistered {
                if canReactivateProximity {
                    startProximityDetection()
                } else {
                    isProximityActivated = false
                    stopProximityDetection()
                }
            } else {
                isProximityActivated = false
                stopProximityDetection()
                clearAllLocalData()
            }
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
                let didSave: Bool = self?.storage.save(localProximity: localProximity) ?? false
                if didSave {
                    self?.didSaveProximity?(receivedProximity)
                }
                self?.didReceiveProximityHandler?()
            }
        })
    }
    
    public func stopProximityDetection() {
        bluetooth.stop()
    }
    
    @objc private func applicationWillTerminate() {
        storage.stop()
    }
    
}

// MARK: - Server methods -
extension RBManager {
    
    public func status(_ completion: @escaping (_ result: Result<RBStatusRiskLevelInfo, Error>) -> ()) {
        guard let ka = ka else {
            completion(.failure(NSError.rbLocalizedError(message: "No key found to make request", code: 0)))
            return
        }
        guard let epoch = currentEpochOrLast else {
            completion(.failure(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0)))
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let statusMessage: RBStatusMessage = try RBMessageGenerator.generateStatusMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            lastStatusRequestDate = Date()
            server.status(epochId: statusMessage.epochId, ebid: statusMessage.ebid, time: statusMessage.time, mac: statusMessage.mac) { result in
                switch result {
                case let .success(response):
                    do {
                        try self.processStatusResponse(response)
                        self.clearOldLocalProximities()
                        
                        var lastRiskScoringDate: Date?
                        if let lastScoringDateTimestampString = response.lastRiskScoringDate {
                            lastRiskScoringDate = Date(timeIntervalSince1900: Int(lastScoringDateTimestampString) ?? 0)
                        }
                        
                        var lastContactDate: Date?
                        if let lastContactDateTimestampString = response.lastContactDate {
                            lastContactDate = Date(timeIntervalSince1900: Int(lastContactDateTimestampString) ?? 0)
                        }
                        
                        let info: RBStatusRiskLevelInfo = RBStatusRiskLevelInfo(riskLevel: response.riskLevel,
                                                                                lastContactDate: lastContactDate,
                                                                                lastRiskScoringDate: lastRiskScoringDate)
                        completion(.success(info))
                    } catch {
                        self.storage.saveLastStatusErrorDate(Date())
                        completion(.failure(error))
                    }
                case let .failure(error):
                    if (error as NSError).code != NSError.lostConnectionCode {
                        self.storage.saveLastStatusErrorDate(Date())
                    }
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    public func report(code: String, symptomsOrigin: Date?, positiveTestDate: Date?, completion: @escaping (_ error: Error?) -> ()) {
        let originSymptoms: Date? = symptomsOrigin?.rbDateByAddingDays(-(preSymptomsSpan ?? 0))
        let originPositiveTest: Date? = positiveTestDate?.rbDateByAddingDays(-(positiveSampleSpan ?? 0))
        let origin: Date = originSymptoms ?? originPositiveTest ?? .distantPast
        let localHelloMessages: [RBLocalProximity] = storage.getLocalProximityList(from: origin, to: Date())
        do {
            let filteredProximities: [RBLocalProximity] = try filter.filter(proximities: localHelloMessages)
            server.report(code: code, helloMessages: filteredProximities) { result in
                switch result {
                case let .success(token):
                    self.reportToken = token
                    self.reportDate = symptomsOrigin ?? positiveTestDate ?? Date()
                    self.reportDataOriginDate = origin
                    self.reportSymptomsStartDate = symptomsOrigin
                    self.reportPositiveTestDate = positiveTestDate
                    self.clearLocalProximityList()
                    self.isSick = true
                    completion(nil)
                case let .failure(error):
                    completion(error)
                }
            }
        } catch {
            completion(NSError.rbLocalizedError(message: "Filtering of hello messages failed: \(error.localizedDescription)", code: 0))
        }
    }
    
    public func register(captcha: String, captchaId: String, completion: @escaping (_ error: Error?) -> ()) {
        guard let keys: RBECKeys = try? RBKeysManager.generateKeys() else {
            completion(NSError.rbLocalizedError(message: "Impossible to set keys up.", code: 0))
            return
        }
        server.register(captcha: captcha, captchaId: captchaId, publicKey: keys.publicKeyBase64) { result in
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
    
    public func unregister(_ completion: @escaping (_ error: Error?, _ isBlocking: Bool) -> ()) {
        guard isRegistered else {
            isProximityActivated = false
            stopProximityDetection()
            clearAllLocalData()
            completion(nil, false)
            return
        }
        guard let ka = ka else {
            completion(NSError.rbLocalizedError(message: "No key found to make request", code: 0), false)
            return
        }
        guard let epoch = currentEpochOrLast else {
            completion(NSError.rbLocalizedError(message: "No epoch found to make request", code: 0), false)
            return
        }
        do {
            let ntpTimestamp: Int = Date().timeIntervalSince1900
            let unregisterMessage: RBUnregisterMessage = try RBMessageGenerator.generateUnregisterMessage(for: epoch, ntpTimestamp: ntpTimestamp, key: ka)
            server.unregister(epochId: unregisterMessage.epochId, ebid: unregisterMessage.ebid, time: unregisterMessage.time, mac: unregisterMessage.mac, completion: { error in
                if let error = error, (error as NSError).code == -1001 {
                    completion(error, true)
                } else {
                    self.isProximityActivated = false
                    self.stopProximityDetection()
                    self.clearAllLocalData()
                    completion(error, false)
                }
            })
        } catch {
            completion(error, false)
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
        lastStatusReceivedDate = nil
    }
    
    public func clearAllLocalData() {
        storage.clearAll(includingDBKey: false)
    }

    public func clearOldLocalProximities() {
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
    }
    
    private func processStatusResponse(_ response: RBStatusResponse) throws {
        let epochs: [RBEpoch] = try decrypt(tuples: response.tuples)
        let now: Date = Date()
        lastStatusReceivedDate = now
        lastStatusErrorDate = nil
        declarationToken = response.declarationToken
        if !epochs.isEmpty {
            clearLocalEpochs()
            storage.save(epochs: epochs)
        }
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
