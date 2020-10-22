// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  TestingManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RobertSDK
import RealmSwift

final class TestingManager {

    enum FileNameStyle {
        case testerNameDayTimestamp
        case full
    }
    
    static let shared: TestingManager = TestingManager()
    var experience: Experience?  { getCurrentExperience() }
    var fileNameStyle: FileNameStyle = .full
    
    lazy var realm: Realm = { try! Realm.testingDb() }()
    
    let header: String = ["expeCode",
                          "expeType",
                          "expePosition",
                          "deviceName",
                          "deviceModel",
                          "deviceOsVersion",
                          "batteryLevel",
                          "batterySaverMode",
                          "devicePlugged",
                          "deviceDeepSleep",
                          "appState",
                          "deviceOrientation",
                          "appVersion",
                          "bleVersion",
                          "bleDevicesConnected",
                          "receivedMessageEbid",
                          "receivedMessageTx",
                          "receivedMessageTime",
                          "receivedMessageCollectedTime",
                          "receivedMessageCollectedTimeFormatted",
                          "receivedMessageRawRssi",
                          "receivedMessageCalibratedRssi",
                          "myEbid",
                          "myTx",
                          "myRx",
                          "wifiState",
                          "wifiUsed",
                          "cellularState",
                          "testName"].joined(separator: ",")
    
    let filteredHeader: String = ["ecc64",
                                  "ebid64",
                                  "mac64",
                                  "helloTime",
                                  "collectedTime",
                                  "rawRssi",
                                  "calibratedRssi",
                                  "updatedRssi",
                                  "isKept"].joined(separator: ",")
    
    @OptionalUserDefault(key: .currentTestingFileTimestamp)
    private var currentTestingFileTimestamp: Double?
    
    private init() {}
    
    func createNewExperience(testerName: String, fileNameStyle: FileNameStyle) {
        let now: Date = Date()
        let experience: Experience = Experience(code: now.testCodeFormatted(),
                                                type: .field,
                                                deviceName: testerName,
                                                testName: now.testCodeFormatted(),
                                                position: "x",
                                                startDate: now)
        createNewExperience(experience, fileNameStyle: fileNameStyle)
    }
    
    func createNewExperience(_ experience: Experience, fileNameStyle: FileNameStyle) {
        reset()
        self.fileNameStyle = fileNameStyle
        try! realm.write {
            realm.add(experience, update: .all)
        }
    }
    
    func getCurrentExperience() -> Experience? {
        return realm.objects(Experience.self).first
    }
    
    func clearExperience() {
        try! realm.write {
            realm.delete(realm.objects(Experience.self))
        }
    }
    
    func initNewFileIfNeeded() -> Bool {
        guard let todayTimestamp = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 else { return false }
        do {
            if todayTimestamp != currentTestingFileTimestamp {
                currentTestingFileTimestamp = todayTimestamp
                try header.data(using: .utf8)?.write(to: currentCsvFileUrl(), options: .atomic)
            }
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func addEntry(receivedProximity: RBReceivedProximity, currentEbid: String) {
        guard let experience = experience else { return }
        guard initNewFileIfNeeded() else { return }
        let eccString: String? = TestingManager.getEcc(from: receivedProximity.data)?.base64EncodedString()
        let ebidString: String? = TestingManager.getEbid(from: receivedProximity.data)?.base64EncodedString()
        let timeInt: UInt16? = TestingManager.getTime(from: receivedProximity.data)
        let macString: String? = TestingManager.getMac(from: receivedProximity.data)?.base64EncodedString()
        guard let ecc = eccString, let ebid = ebidString, let time = timeInt, let mac = macString else {
            return
        }
        let proximity: RBLocalProximity = RBLocalProximity(ecc: ecc,
                                                           ebid: ebid,
                                                           mac: mac,
                                                           timeFromHelloMessage: time,
                                                           timeCollectedOnDevice: receivedProximity.timeCollectedOnDevice,
                                                           rssiRaw: receivedProximity.rssiRaw,
                                                           rssiCalibrated: receivedProximity.rssiCalibrated,
                                                           tx: receivedProximity.tx)
        let values: [String] = [experience.code?.cleaningForCSV() ?? "-",
                                Experience.ExpType(rawValue: experience.type)?.technicalValue ?? "-",
                                experience.position?.cleaningForCSV() ?? "-",
                                experience.deviceName?.cleaningForCSV() ?? "-",
                                DeviceInfoManager.shared.modelName.cleaningForCSV(),
                                DeviceInfoManager.shared.osVersion.cleaningForCSV(),
                                DeviceInfoManager.shared.batteryLevel,
                                DeviceInfoManager.shared.batterySaverMode,
                                DeviceInfoManager.shared.devicePluggedState,
                                "-",
                                DeviceInfoManager.shared.appState,
                                DeviceInfoManager.shared.orientation,
                                DeviceInfoManager.shared.appVersion,
                                DeviceInfoManager.shared.bleVersion,
                                "\(DeviceInfoManager.shared.connectedBleDevicesCount)",
                                proximity.ebid,
                                "\(proximity.tx)",
                                "\(proximity.timeFromHelloMessage)",
                                "\(proximity.timeCollectedOnDevice)",
                                "\(Date(timeIntervalSince1900: proximity.timeCollectedOnDevice).fullDateFormatted())",
                                "\(proximity.rssiRaw)",
                                "\(proximity.rssiCalibrated)",
                                currentEbid,
                                DeviceInfoManager.shared.bleDeviceParameters?.txFactor.truncatedStringValue ?? "-",
                                DeviceInfoManager.shared.bleDeviceParameters?.rxFactor.truncatedStringValue ?? "-",
                                DeviceInfoManager.shared.isWifiOnState,
                                DeviceInfoManager.shared.isWifiUsedState,
                                DeviceInfoManager.shared.isCellularOnState,
                                experience.testName ?? "-"]
        let lineString: String = "\n" + values.joined(separator: ",")
        do {
            try lineString.data(using: .utf8)?.append(fileURL: currentCsvFileUrl())
        } catch {
            print(error)
        }
    }
    
    func allTestFilesUrls() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: csvDirectoryUrl(), includingPropertiesForKeys: nil, options: [])) ?? []
    }
    
    func setPosition(_ position: String) {
        guard let currentExperience = getCurrentExperience() else { return }
        try! realm.write {
            currentExperience.position = position
        }
    }
    
    func setEndDate(_ date: Date) {
        guard let currentExperience = getCurrentExperience() else { return }
        try! realm.write {
            currentExperience.endDate = date
        }
    }
    
    func cleanFiles() {
        allTestFilesUrls().enumerated().forEach { _, url in
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func reset() {
        clearExperience()
        currentTestingFileTimestamp = nil
        cleanFiles()
    }
    
    func currentCsvFileUrl() -> URL {
        let fileName: String
        switch fileNameStyle {
        case .testerNameDayTimestamp:
            let testerName: String = (experience?.deviceName ?? "unknownTester").cleaningForServerFileName()
            fileName = "\(testerName)-\(Int(currentTestingFileTimestamp ?? 0.0)).csv"
        case .full:
            let todaySuffix: String = Date(timeIntervalSince1970: currentTestingFileTimestamp ?? 0.0).underscoreDateFormatted()
            let expeCode: String = experience?.code ?? "-"
            let testName: String = experience?.testName ?? "-"
            let deviceName: String = experience?.deviceName ?? "-"
            let startDateTimestamp: Int = Int(experience?.startDate?.timeIntervalSince1970 ?? 0.0)
            fileName = "\(expeCode)-\(testName)-\(deviceName)-\(startDateTimestamp)-\(todaySuffix).csv"
        }
        return csvDirectoryUrl().appendingPathComponent(fileName)
    }
    
    func csvDirectoryUrl() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("csv")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
}

extension TestingManager {
    
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
        let time: UInt16 = [UInt8](timeData).withUnsafeBufferPointer { $0.baseAddress?.withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }.bigEndian } ?? 0
        return time
    }
    
    static func getMac(from helloMessage: Data) -> Data? {
        guard helloMessage.count >= 16 else { return nil }
        return helloMessage[11..<16]
    }
    
}

extension Realm {
    
    static func testingDb() throws -> Realm {
        return try Realm(configuration: testingConfiguration())
    }
    
    static private func dbsDirectoryUrl() -> URL {
        var directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("DBs")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
            try? directoryUrl.addSkipBackupAttribute()
        }
        return directoryUrl
    }
    
    static private func testingConfiguration() -> Realm.Configuration {
        let classes: [Object.Type] = [Experience.self,
                                      Permission.self,
                                      PermissionRole.self,
                                      PermissionUser.self]
        let databaseUrl: URL = dbsDirectoryUrl().appendingPathComponent("testing.realm")
        let userConfig: Realm.Configuration = Realm.Configuration(fileURL: databaseUrl, schemaVersion: 1, migrationBlock: { _, _ in }, objectTypes: classes)
        return userConfig
    }
    
}
