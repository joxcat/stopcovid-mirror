// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StorageManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
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
        case lastRiskReceivedDate
        case isSick
        case positiveToSymptoms
        case pushToken
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
           if let date = date {
               keychain.set("\(date.timeIntervalSince1970)", forKey: KeychainKey.lastStatusRequestDate.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
           } else {
               keychain.delete(KeychainKey.lastStatusRequestDate.rawValue)
           }
           notifyStatusDataChanged()
       }

       public func lastStatusRequestDate() -> Date? {
           guard let timestampString = keychain.get(KeychainKey.lastStatusRequestDate.rawValue), let timestamp = Double(timestampString) else { return nil }
           return Date(timeIntervalSince1970: timestamp)
       }
    
    // MARK: - Status: last status received date -
    public func saveLastStatusReceivedDate(_ date: Date?) {
        if let date = date {
            keychain.set("\(date.timeIntervalSince1970)", forKey: KeychainKey.lastStatusReceivedDate.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(KeychainKey.lastStatusReceivedDate.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    public func lastStatusReceivedDate() -> Date? {
        guard let timestampString = keychain.get(KeychainKey.lastStatusReceivedDate.rawValue), let timestamp = Double(timestampString) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Status: last risk received date -
    public func saveLastRiskReceivedDate(_ date: Date?) {
        if let date = date {
            keychain.set("\(date.timeIntervalSince1970)", forKey: KeychainKey.lastRiskReceivedDate.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(KeychainKey.lastRiskReceivedDate.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    public func lastRiskReceivedDate() -> Date? {
        guard let timestampString = keychain.get(KeychainKey.lastRiskReceivedDate.rawValue), let timestamp = Double(timestampString) else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Status: Is sick -
    public func save(isSick: Bool) {
        keychain.set(isSick, forKey: KeychainKey.isSick.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        notifyStatusDataChanged()
    }
    
    public func isSick() -> Bool {
        keychain.getBool(KeychainKey.isSick.rawValue) ?? false
    }
    
    // MARK: - Push token -
    public func save(pushToken: String?) {
        if let pushToken = pushToken {
            keychain.set(pushToken, forKey: KeychainKey.pushToken.rawValue, withAccess: .accessibleAfterFirstUnlockThisDeviceOnly)
        } else {
            keychain.delete(KeychainKey.pushToken.rawValue)
        }
        notifyStatusDataChanged()
    }
    
    public func pushToken() -> String? {
        keychain.get(KeychainKey.pushToken.rawValue)
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
        deleteDb(includingFile: includingDBKey)
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

private extension StorageManager {
    
    func notifyStatusDataChanged() {
        NotificationCenter.default.post(name: .statusDataDidChange, object: nil)
    }
    
    func notifyLocalProximityDataChanged() {
        NotificationCenter.default.post(name: .localProximityDataDidChange, object: nil)
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
                                      Permission.self,
                                      PermissionRole.self,
                                      PermissionUser.self]
        let databaseUrl: URL = dbsDirectoryUrl().appendingPathComponent("db.realm")
        let userConfig: Realm.Configuration = Realm.Configuration(fileURL: databaseUrl, encryptionKey: key, schemaVersion: 6, migrationBlock: { _, _ in }, objectTypes: classes)
        return userConfig
    }
    
}
