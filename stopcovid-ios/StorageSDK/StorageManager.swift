// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StorageManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the TousAntiCovid project.
//

import UIKit
import KeychainSwift
import RealmSwift
import RobertSDK

public final class StorageManager: RBStorage {
    
    enum KeychainKey: String, CaseIterable {
        case dbKey
        case epochTimeStart
        case ka
        case kea
        case proximityActivated
        case isAtRisk
        case lastExposureTimeFrame
        case lastStatusRequestDate
        case lastStatusReceivedDate
        case lastStatusErrorDate
        case lastRiskReceivedDate
        case isSick
        case positiveToSymptoms
        case pushToken
        case reportDate
        case reportDataOriginDate
        case reportSymptomsStartDate
        case reportPositiveTestDate
        case reportToken
        case lastWarningRiskReceivedDate
        case currentWarningRiskScoringDate
        case currentRiskScoringDate
        
        case isolationState
        case isolationLastContactDate
        case isolationIsKnownIndexAtHome
        case isolationKnowsIndexSymptomsEndDate
        case isolationIndexSymptomsEndDate
        case isolationIsTestNegative
        case isolationPositiveTestingDate
        case isolationIsHavingSymptoms
        case isolationSymptomsStartDate
        case isolationIsStillHavingFever
        case isolationIsFeverReminderScheduled
    }
    
    let keychain: KeychainSwift = KeychainSwift(keyPrefix: "SC")
    private var realm: Realm?
    
    public init() {}
    
    public func start() {
        loadDb()
    }
    
    public func stop() {
        realm = nil
    }
    
    // MARK: - Epoch -
    public func save(epochs: [RBEpoch]) {
        guard let realm = realm else { return }
        let realmEpochs: [RealmEpoch] = epochs.map { RealmEpoch.from(epoch: $0) }
        try! realm.write {
            realm.add(realmEpochs, update: .all)
        }
    }
    
    public func getCurrentEpoch(defaultingToLast: Bool) -> RBEpoch? {
        do {
            let timeStart: Int = try getTimeStart()
            let now: Int = Date().timeIntervalSince1900
            let quartersCount: Int = Int(Double(now - timeStart) / Double(RBConstants.epochDurationInSeconds))
            return getEpoch(for: quartersCount) ?? (defaultingToLast ? getLastEpoch() : nil)
        } catch {
            return nil
        }
    }
    
    public func getEpoch(for id: Int) -> RBEpoch? {
        guard let realm = realm else { return nil }
        return realm.object(ofType: RealmEpoch.self, forPrimaryKey: id)?.toRBEpoch()
    }
    
    public func getLastEpoch() -> RBEpoch? {
        guard let realm = realm else { return nil }
        return realm.objects(RealmEpoch.self).sorted { $0.epochId < $1.epochId }.last?.toRBEpoch()
    }
    
    public func epochsCount() -> Int {
        guard let realm = realm else { return 0 }
        return realm.objects(RealmEpoch.self).count
    }
    
    // MARK: - TimeStart -
    public func save(timeStart: Int) throws {
        guard let data = "\(timeStart)".data(using: .utf8) else { throw NSError.stLocalizedError(message: "Can't generate data from timeStart", code: 400) }
        keychain.set(data, forKey: KeychainKey.epochTimeStart.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func getTimeStart() throws -> Int {
        guard let data = keychain.getData(KeychainKey.epochTimeStart.rawValue) else { throw NSError.stLocalizedError(message: "timeStart not found in Keychain", code: 404) }
        guard let timeString = String(data: data, encoding: .utf8),
              let timeStart = Int(timeString) else { throw NSError.stLocalizedError(message: "Can't generate Int from timeStart data", code: 400) }
        return timeStart
    }
    
    // MARK: - Keys -
    public func save(ka: Data) {
        keychain.set(ka, forKey: KeychainKey.ka.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func getKa() -> Data? {
        keychain.getData(KeychainKey.ka.rawValue)
    }
    
    public func save(kea: Data) {
        keychain.set(kea, forKey: KeychainKey.kea.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    public func getKea() -> Data? {
        keychain.getData(KeychainKey.kea.rawValue)
    }
    
    public func areKeysStored() -> Bool {
        getKa() != nil && getKea() != nil
    }
    
    // MARK: - Local Proximity -
    public func save(localProximity: RBLocalProximity) -> Bool {
        guard let realm = realm else { return false }
        let proximity: RealmLocalProximity = RealmLocalProximity.from(localProximity: localProximity)
        if realm.object(ofType: RealmLocalProximity.self, forPrimaryKey: proximity.id) == nil {
            try! realm.write {
                realm.add(proximity, update: .all)
            }
            notifyLocalProximityDataChanged()
            return true
        } else {
            return false
        }
    }
    
    public func getLocalProximityList() -> [RBLocalProximity] {
        guard let realm = realm else { return [] }
        return realm.objects(RealmLocalProximity.self).map { $0.toRBLocalProximity() }
    }
    
    public func getLocalProximityList(from: Date, to: Date) -> [RBLocalProximity] {
        guard let realm = realm else { return [] }
        let proximities: [RealmLocalProximity] = [RealmLocalProximity](realm.objects(RealmLocalProximity.self))
        let matchingProximities: [RealmLocalProximity] = proximities.filter { $0.timeCollectedOnDevice >= from.timeIntervalSince1900 && $0.timeCollectedOnDevice <= to.timeIntervalSince1900 }
        return matchingProximities.map { $0.toRBLocalProximity() }
    }
    
    public func clearProximityList(before date: Date) {
        guard let realm = realm else { return }
        let proximities: [RealmLocalProximity] = [RealmLocalProximity](realm.objects(RealmLocalProximity.self))
        let proximitiesToDelete: [RealmLocalProximity] = proximities.filter { $0.timeCollectedOnDevice < date.timeIntervalSince1900 }
        if !proximitiesToDelete.isEmpty {
            try! realm.write {
                realm.delete(proximitiesToDelete)
            }
        }
    }
    
    // MARK: - Proximity -
    public func save(proximityActivated: Bool) {
        UserDefaults.standard.set(proximityActivated, forKey: KeychainKey.proximityActivated.rawValue)
        UserDefaults.standard.synchronize()
        notifyStatusDataChanged()
    }
    
    public func isProximityActivated() -> Bool {
        if let bool = UserDefaults.standard.object(forKey: KeychainKey.proximityActivated.rawValue) as? Bool {
            return bool
        } else {
            let bool: Bool = keychain.getBool(KeychainKey.proximityActivated.rawValue) ?? false
            save(proximityActivated: bool)
            return bool
        }
    }
    
    // MARK: - Status: isAtRisk -
    public func clearIsAtRisk() {
        keychain.delete(KeychainKey.isAtRisk.rawValue)
    }
    
    public func isAtRisk() -> Bool? {
        keychain.getBool(KeychainKey.isAtRisk.rawValue)
    }
    
    // MARK: - Status: last exposure time frame -
    public func save(lastExposureTimeFrame: Int?) {
        if let lastExposureTimeFrame = lastExposureTimeFrame {
            keychain.set("\(lastExposureTimeFrame)", forKey: KeychainKey.lastExposureTimeFrame.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(KeychainKey.lastExposureTimeFrame.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    public func lastExposureTimeFrame() -> Int? {
        guard let lastExposureString = keychain.get(KeychainKey.lastExposureTimeFrame.rawValue), let lastExposure = Int(lastExposureString) else { return nil }
        return lastExposure
    }

    // MARK: - Status: last status request date -
    public func saveLastStatusRequestDate(_ date: Date?) {
        saveDate(date, key: .lastStatusRequestDate)
    }
    
    public func lastStatusRequestDate() -> Date? {
        getDate(key: .lastStatusRequestDate)
    }
    
    // MARK: - Status: last status received date -
    public func saveLastStatusReceivedDate(_ date: Date?) {
        saveDate(date, key: .lastStatusReceivedDate)
    }
    
    public func lastStatusReceivedDate() -> Date? {
        getDate(key: .lastStatusReceivedDate)
    }
    
    // MARK: - Status: last status error date -
    public func saveLastStatusErrorDate(_ date: Date?) {
        saveDate(date, key: .lastStatusErrorDate)
    }
    
    public func lastStatusErrorDate() -> Date? {
        getDate(key: .lastStatusErrorDate)
    }
    
    // MARK: - Status: last risk received date -
    public func saveLastRiskReceivedDate(_ date: Date?) {
        saveDate(date, key: .lastRiskReceivedDate)
    }
    
    public func lastRiskReceivedDate() -> Date? {
        getDate(key: .lastRiskReceivedDate)
    }
    
    public func saveCurrentRiskScoringDate(_ date: Date?) {
        saveDate(date, key: .currentRiskScoringDate)
    }
    
    public func currentRiskScoringDate() -> Date? {
        getDate(key: .currentRiskScoringDate)
    }
    
    // MARK: - Status: Is sick -
    public func save(isSick: Bool) {
        saveBool(bool: isSick, key: .isSick)
    }
    
    public func isSick() -> Bool {
        keychain.getBool(KeychainKey.isSick.rawValue) ?? false
    }
    
    // MARK: - Push token -
    public func save(pushToken: String?) {
        saveString(string: pushToken, key: .pushToken)
    }
    
    public func pushToken() -> String? {
        keychain.get(KeychainKey.pushToken.rawValue)
    }
    
    // MARK: - Report dates -
    public func saveReportDate(_ date: Date?) {
        saveDate(date, key: .reportDate)
    }
    
    public func reportDate() -> Date? {
        getDate(key: .reportDate)
    }
    
    public func saveReportDataOriginDate(_ date: Date?) {
        saveDate(date, key: .reportDataOriginDate)
    }
    
    public func reportDataOriginDate() -> Date? {
        getDate(key: .reportDataOriginDate)
    }
    
    public func saveReportSymptomsStartDate(_ date: Date?) {
        saveDate(date, key: .reportSymptomsStartDate)
    }
    
    public func reportSymptomsStartDate() -> Date? {
        getDate(key: .reportSymptomsStartDate)
    }
    
    public func saveReportPositiveTestDate(_ date: Date?) {
        saveDate(date, key: .reportPositiveTestDate)
    }
    
    public func reportPositiveTestDate() -> Date? {
        getDate(key: .reportPositiveTestDate)
    }
    
    // MARK: - Report token -
    public func saveReportToken(_ token: String?) {
        saveString(string: token, key: .reportToken, notify: false)
    }
    
    public func reportToken() -> String? {
        keychain.get(KeychainKey.reportToken.rawValue)
    }

    // MARK: - Warning Status: isAtRisk for Venues -
    public func saveLastWarningRiskReceivedDate(_ date: Date?) {
        saveDate(date, key: .lastWarningRiskReceivedDate)
    }
    
    public func lastWarningRiskReceivedDate() -> Date? {
        getDate(key: .lastWarningRiskReceivedDate)
    }
    
    public func saveCurrentWarningRiskScoringDate(_ date: Date?) {
        saveDate(date, key: .currentWarningRiskScoringDate)
    }
    
    public func currentWarningRiskScoringDate() -> Date? {
        getDate(key: .currentWarningRiskScoringDate)
    }
    
    // MARK: - Isolation -
    public func saveIsolationState(_ state: String?) {
        saveString(string: state, key: .isolationState, notify: false)
    }
    
    public func isolationState() -> String? {
        keychain.get(KeychainKey.isolationState.rawValue)
    }
    
    public func saveIsolationLastContactDate(_ date: Date?) {
        saveDate(date, key: .isolationLastContactDate, notify: false)
    }
    
    public func isolationLastContactDate() -> Date? {
        getDate(key: .isolationLastContactDate)
    }
    
    public func saveIsolationIsKnownIndexAtHome(_ isAtHome: Bool?) {
        saveBool(bool: isAtHome, key: .isolationIsKnownIndexAtHome, notify: false)
    }
    
    public func isolationIsKnownIndexAtHome() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsKnownIndexAtHome.rawValue)
    }
    
    public func saveIsolationKnowsIndexSymptomsEndDate(_ knowsEndDate: Bool?) {
        saveBool(bool: knowsEndDate, key: .isolationKnowsIndexSymptomsEndDate, notify: false)
    }
    
    public func isolationKnowsIndexSymptomsEndDate() -> Bool? {
        keychain.getBool(KeychainKey.isolationKnowsIndexSymptomsEndDate.rawValue)
    }
    
    public func saveIsolationIndexSymptomsEndDate(_ date: Date?) {
        saveDate(date, key: .isolationIndexSymptomsEndDate, notify: false)
    }
    
    public func isolationIndexSymptomsEndDate() -> Date? {
        getDate(key: .isolationIndexSymptomsEndDate)
    }
    
    public func saveIsolationIsTestNegative(_ isTestNegative: Bool?) {
        saveBool(bool: isTestNegative, key: .isolationIsTestNegative, notify: false)
    }
    
    public func isolationIsTestNegative() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsTestNegative.rawValue)
    }
    
    public func saveIsolationPositiveTestingDate(_ date: Date?) {
        saveDate(date, key: .isolationPositiveTestingDate, notify: false)
    }
    
    public func isolationPositiveTestingDate() -> Date? {
        getDate(key: .isolationPositiveTestingDate)
    }
    
    public func saveIsolationIsHavingSymptoms(_ havingSymptoms: Bool?) {
        saveBool(bool: havingSymptoms, key: .isolationIsHavingSymptoms, notify: false)
    }
    
    public func isolationIsHavingSymptoms() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsHavingSymptoms.rawValue)
    }
    
    public func saveIsolationSymptomsStartDate(_ date: Date?) {
        saveDate(date, key: .isolationSymptomsStartDate, notify: false)
    }
    
    public func isolationSymptomsStartDate() -> Date? {
        getDate(key: .isolationSymptomsStartDate)
    }
    
    public func saveIsolationIsStillHavingFever(_ stillHavingFever: Bool?) {
        saveBool(bool: stillHavingFever, key: .isolationIsStillHavingFever, notify: false)
    }
    
    public func isolationIsStillHavingFever() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsStillHavingFever.rawValue)
    }
    
    public func saveIsolationIsFeverReminderScheduled(_ isScheduled: Bool?) {
        saveBool(bool: isScheduled, key: .isolationIsFeverReminderScheduled, notify: false)
    }
    
    public func isolationIsFeverReminderScheduled() -> Bool? {
        keychain.getBool(KeychainKey.isolationIsFeverReminderScheduled.rawValue)
    }
    
    private func saveDate(_ date: Date?, key: KeychainKey, notify: Bool = true) {
        if let date = date {
            keychain.set("\(date.timeIntervalSince1970)", forKey: key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(key.rawValue)
        }
        guard notify else { return }
        notifyStatusDataChanged()
    }
    
    private func getDate(key: KeychainKey) -> Date? {
        guard let timestampString = keychain.get(key.rawValue), let timestamp = Double(timestampString) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func saveString(string: String?, key: KeychainKey, notify: Bool = true) {
        if let string = string {
            keychain.set(string, forKey: key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(key.rawValue)
        }
        guard notify else { return }
        notifyStatusDataChanged()
    }
    
    private func saveBool(bool: Bool?, key: KeychainKey, notify: Bool = true) {
        if let bool = bool {
            keychain.set(bool, forKey: key.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(key.rawValue)
        }
        guard notify else { return }
        notifyStatusDataChanged()
    }
    
    // MARK: - Data cleraing -
    public func clearLocalEpochs() {
       guard let realm = realm else { return }
        try! realm.write {
            realm.delete(realm.objects(RealmEpoch.self))
        }
    }
    
    public func clearLocalProximityList() {
        guard let realm = realm else { return }
        try! realm.write {
            realm.delete(realm.objects(RealmLocalProximity.self))
        }
        notifyLocalProximityDataChanged()
    }
    
    public func clearAll(includingDBKey: Bool) {
        KeychainKey.allCases.forEach {
            if $0 != .dbKey || includingDBKey {
                keychain.delete($0.rawValue)
            }
        }
        deleteAllAttestationFields()
        deleteDb(includingFile: includingDBKey)
        notifyStatusDataChanged()
    }
    
    private func deleteDb(includingFile: Bool) {
        try? realm?.write {
            realm?.deleteAll()
        }
        if includingFile {
            realm = nil
            Realm.deleteDb()
        }
    }
    
    // MARK: - DB Key -
    private func loadDb() {
        if let key = getDbKey() {
            realm = try! Realm.db(key: key)
        } else if let newKey = Realm.generateEncryptionKey(), !keychain.allKeys.contains("SC\(KeychainKey.dbKey.rawValue)") {
            deleteDb(includingFile: true)
            realm = try! Realm.db(key: newKey)
            save(dbKey: newKey)
        }
    }
    
    private func save(dbKey: Data) {
        keychain.set(dbKey, forKey: KeychainKey.dbKey.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
    }
    
    private func getDbKey() -> Data? {
        keychain.getData(KeychainKey.dbKey.rawValue)
    }
    
}

public extension StorageManager {
    
    func saveAttestation(_ attestation: Attestation) {
        guard let realm = realm else { return }
        let realmAttestation: RealmAttestation = RealmAttestation.from(attestation: attestation)
        try! realm.write {
            realm.add(realmAttestation, update: .all)
        }
        notifyAttestationDataChanged()
    }
    
    func attestations() -> [Attestation] {
        guard let realm = realm else { return [] }
        return realm.objects(RealmAttestation.self).map { $0.toAttestation() }
    }
    
    func deleteAttestationsData() {
        guard let realm = realm else { return }
        try! realm.write {
            realm.delete(realm.objects(RealmAttestation.self))
        }
        notifyAttestationDataChanged()
    }
    
    func deleteAttestation(_ attestation: Attestation) {
        guard let realm = realm else { return }
        if let attestation = realm.object(ofType: RealmAttestation.self, forPrimaryKey: attestation.id) {
            try! realm.write {
                realm.delete(attestation)
            }
        }
        notifyAttestationDataChanged()
    }
    
    func deleteExpiredAttestationsData(durationInHours: Double) {
        guard let realm = realm else { return }
        let now: Date = Date()
        let expiredAttestations: [RealmAttestation] = [RealmAttestation](realm.objects(RealmAttestation.self)).filter { attestation in
            (now.timeIntervalSince1970 - Double(attestation.timestamp)) >= durationInHours * 3600.0
        }
        try! realm.write {
            realm.delete(expiredAttestations)
        }
        notifyAttestationDataChanged()
    }
    
    func saveAttestationFieldValueForKey(_ key: String, value: String?) {
        let keychainKey: String = "attestation-\(key)"
        if let value = value {
            keychain.set(value, forKey: keychainKey, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(keychainKey)
        }
    }
    
    func getAttestationFieldValues() -> [String: String] {
        var fieldValues: [String: String] = [:]
        keychain.allKeys.forEach { key in
            if key.hasPrefix("SCattestation-") {
                fieldValues[key.replacingOccurrences(of: "SCattestation-", with: "")] = keychain.get(key.replacingOccurrences(of: "SC", with: ""))
            }
        }
        return fieldValues
    }
    
    func getAttestationFieldValueForKey(_ key: String) -> String? {
        let keychainKey: String = "attestation-\(key)"
        return keychain.get(keychainKey)
    }
    
    func deleteAllAttestationFields() {
        keychain.allKeys.forEach { key in
            if key.hasPrefix("SCattestation-") {
                keychain.delete(key.replacingOccurrences(of: "SC", with: ""))
            }
        }
    }
    
}

public extension StorageManager {

    func saveVenueQrCode(_ venueQrCode: VenueQrCode) {
        guard let realm = realm else { return }
        let realmVenueQrCode: RealmVenueQrCode = RealmVenueQrCode.from(venueQrCode: venueQrCode)
        try! realm.write {
            realm.add(realmVenueQrCode, update: .all)
        }
        notifyVenueQrCodeDataChanged()
    }
    
    func deleteVenueQrCode(_ venueQrCode: VenueQrCode) {
        guard let realm = realm else { return }
        guard let realmVenueQrCode = realm.object(ofType: RealmVenueQrCode.self, forPrimaryKey: venueQrCode.id) else { return }
        try! realm.write {
            realm.delete(realmVenueQrCode)
        }
        notifyVenueQrCodeDataChanged()
    }

    func venuesQrCodes() -> [VenueQrCode] {
        guard let realm = realm else { return [] }
        return realm.objects(RealmVenueQrCode.self).map { $0.toVenueQrCode() }
    }

    func deleteVenuesQrCodeData() {
        guard let realm = realm else { return }
        try! realm.write {
            realm.delete(realm.objects(RealmVenueQrCode.self))
        }
        notifyVenueQrCodeDataChanged()
    }
    
    func deleteExpiredVenuesQrCodeData(durationInSeconds: Double) {
        guard let realm = realm else { return }
        let now: Date = Date()
        let expiredVenueQrCodes: [RealmVenueQrCode] = [RealmVenueQrCode](realm.objects(RealmVenueQrCode.self)).filter { venueQrCode in
            (Double(now.timeIntervalSince1900) - Double(venueQrCode.ntpTimestamp)) >= durationInSeconds
        }
        try! realm.write {
            realm.delete(expiredVenueQrCodes)
        }
        notifyVenueQrCodeDataChanged()
    }

}

private extension StorageManager {
    
    func notifyStatusDataChanged() {
        NotificationCenter.default.post(name: .statusDataDidChange, object: nil)
    }
    
    func notifyLocalProximityDataChanged() {
        NotificationCenter.default.post(name: .localProximityDataDidChange, object: nil)
    }
    
    func notifyAttestationDataChanged() {
        NotificationCenter.default.post(name: .attestationDataDidChange, object: nil)
    }

    func notifyVenueQrCodeDataChanged() {
        NotificationCenter.default.post(name: .venueQrCodeDataDidChange, object: nil)
    }
    
}

private extension Realm {
    
    static func db(key: Data?) throws -> Realm {
        guard let key = key else { throw NSError.stLocalizedError(message: "Impossible to decrypt the database", code: 0) }
        return try Realm(configuration: configuration(key: key))
    }
    
    static func deleteDb() {
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.realm"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.lock"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.note"))
        try? FileManager.default.removeItem(at: dbsDirectoryUrl().appendingPathComponent("db.management"))
    }
    
    static func generateEncryptionKey() -> Data? {
        var keyData: Data = Data(count: 64)
        let result: Int32 = keyData.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 64, $0.baseAddress!) }
        return result == errSecSuccess ? keyData : nil
    }
    
    static private func dbsDirectoryUrl() -> URL {
        var directoryUrl: URL = FileManager.stLibraryDirectory().appendingPathComponent("DBs")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
            try? directoryUrl.stAddSkipBackupAttribute()
        }
        return directoryUrl
    }
    
    static private func configuration(key: Data) -> Realm.Configuration {
        let classes: [Object.Type] = [RealmEpoch.self,
                                      RealmLocalProximity.self,
                                      RealmAttestation.self,
                                      RealmVenueQrCode.self,
                                      Permission.self,
                                      PermissionRole.self,
                                      PermissionUser.self]
        let databaseUrl: URL = dbsDirectoryUrl().appendingPathComponent("db.realm")
        let userConfig: Realm.Configuration = Realm.Configuration(fileURL: databaseUrl, encryptionKey: key, schemaVersion: 14, migrationBlock: { _, _ in }, objectTypes: classes)
        return userConfig
    }
    
}
