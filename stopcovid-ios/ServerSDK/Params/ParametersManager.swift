// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ParametersManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 14/05/2020 - for the TousAntiCovid project.
//


import UIKit
import RobertSDK

public final class ParametersManager: NSObject {
    
    typealias RequestCompletion = (_ result: Result<Double, Error>) -> ()
    
    public enum ApiVersion: String {
        case v3
        case v4
    }
    
    public enum WarningApiVersion: String {
        case v1
    }
    
    public static let shared: ParametersManager = ParametersManager()
    var url: URL!
    var certificateFile: Data!
    
    public var minHourContactNotif: Int? {
        guard let hour = valueFor(name: "app.minHourContactNotif") as? Double else { return nil }
        return Int(hour)
    }
    public var maxHourContactNotif: Int? {
           guard let hour = valueFor(name: "app.maxHourContactNotif") as? Double else { return nil }
           return Int(hour)
       }
    
    public var displayRecordVenues: Bool { valueFor(name: "app.displayRecordVenues") as? Bool ?? false }
    public var displayPrivateEvent: Bool { valueFor(name: "app.displayPrivateEvent") as? Bool ?? false }
    public var privateEventVenueType: String { valueFor(name: "app.privateEventVenueType") as? String ?? "NA" }
    public var displayAttestation: Bool { valueFor(name: "app.displayAttestation") as? Bool ?? false }
    
    public var displayIsolation: Bool { valueFor(name: "app.displayIsolation") as? Bool ?? false }
    public var displayVaccination: Bool { valueFor(name: "app.displayVaccination") as? Bool ?? false }
    public var vaccinationCentersCount: Int { valueFor(name: "app.vaccinationCentersCount") as? Int ?? 5 }
    public var isolationDuration: Double { valueFor(name: "app.isolation.duration") as? Double ?? 604800.0 }
    public var postIsolationDuration: Double { valueFor(name: "app.postIsolation.duration") as? Double ?? 604800.0 }
    
    var appAvailability: Bool? { valueFor(name: "app.appAvailability") as? Bool }
    var preSymptomsSpan: Int? {
        guard let span = valueFor(name: "app.preSymptomsSpan") as? Double else { return nil }
        return Int(span)
    }
    var positiveSampleSpan: Int? {
        guard let span = valueFor(name: "app.positiveSampleSpan") as? Double else { return nil }
        return Int(span)
    }

    public var minHoursBetweenVisibleNotif: Int {
        guard let hour = valueFor(name: "app.push.minHoursBetweenVisibleNotifications") as? Double else { return 24 }
        return Int(hour)
    }
    public var proximityReactivationReminderHours: [Double] {
        valueFor(name: "app.proximityReactivation.reminderHours") as? [Double] ?? [1.0, 2.0, 4.0, 8.0, 12.0]
        
    }
    private var minStatusRetryDuration: Double? {
        guard let hour = valueFor(name: "app.minStatusRetryDuration") as? Double else { return nil }
        return Double(hour)
    }
    public var minStatusRetryTimeInterval: Double {
        (minStatusRetryDuration ?? 0.5) * 3600.0
    }
    var checkStatusFrequency: Double? { valueFor(name: "app.checkStatusFrequency") as? Double }
    var randomStatusHour: Double? { valueFor(name: "app.randomStatusHour") as? Double }
    public var pushDisplayOnSuccess: Bool { valueFor(name: "app.push.displayOnSuccess") as? Bool ?? false }
    public var pushDisplayAll: Bool { valueFor(name: "app.push.displayAll") as? Bool ?? false }

    public var displayDepartmentLevel: Bool { valueFor(name: "app.keyfigures.displayDepartmentLevel") as? Bool ?? false }
    
    public var qrCodeDeletionHours: Double { valueFor(name: "app.qrCode.deletionHours") as? Double ?? 24.0}
    public var qrCodeExpiredHours: Double { valueFor(name: "app.qrCode.expiredHours") as? Double ?? 1.0}
    public var qrCodeFormattedString: String { valueFor(name: "app.qrCode.formattedString") as? String ?? "Cree le: <creationDate> a <creationHour>;\nNom: <lastname>;\nPrenom: <firstname>;\nNaissance: <dob> a <cityofbirth>;\nAdresse: <address> <zip> <city>;\nSortie: <datetime-day> a <datetime-hour>;\nMotifs: <reason-code>" }
    public var qrCodeFormattedStringDisplayed: String { valueFor(name: "app.qrCode.formattedStringDisplayed") as? String ?? "Créé le <creationDate> à <creationHour>\nNom : <lastname>;\nPrénom : <firstname>;\nNaissance : <dob> à <cityofbirth>\nAdresse : <address> <zip> <city>\nSortie : <datetime-day> à <datetime-hour>\nMotif: <reason-code>" }
    public var qrCodeFooterString: String { valueFor(name: "app.qrCode.footerString") as? String ?? "<firstname> - <datetime-day>, <datetime-hour>\n<reason-shortlabel>" }
    
    public var statusTimeInterval: Double {
        let randomStatusHour: Double = self.randomStatusHour ?? 0.0
        let interval: Double = (self.checkStatusFrequency ?? 0.0) * 3600.0 + (randomStatusHour == 0.0 ? 0.0 : Double.random(in: 0..<randomStatusHour * 3600.0))
        return interval
    }
    public var quarantinePeriod: Int? {
        guard let period = valueFor(name: "app.quarantinePeriod") as? Double else { return nil }
        return Int(period)
    }
    public var venuesTimestampRoundingInterval: Int {
        guard let interval = valueFor(name: "app.venuesTimestampRoundingInterval") as? Double else { return 900 }
        return Int(interval)
    }
    public var venuesRetentionPeriod: Int {
        guard let period = valueFor(name: "app.venuesRetentionPeriod") as? Double else { return 14 }
        return Int(period)
    }

    public var venuesSalt: Int {
        guard let period = valueFor(name: "app.venuesSalt") as? Double else { return 1000 }
        return Int(period)
    }

    var dataRetentionPeriod: Int {
        guard let period = valueFor(name: "app.dataRetentionPeriod") as? Double else { return 14 }
        return Int(period)
    }
    public var bleServiceUuid: String? { valueFor(name: "ble.serviceUUID") as? String }
    public var bleCharacteristicUuid: String? { valueFor(name: "ble.characteristicUUID") as? String }
    public var bleFilteringConfig: String? { valueFor(name: "ble.filterConfig") as? String }
    public var bleFilteringMode: String? { valueFor(name: "ble.filterMode") as? String }
    
    public var apiVersion: ApiVersion { ApiVersion(rawValue: valueFor(name: "app.apiVersion") as? String ?? "") ?? .v3 }
    public var warningApiVersion: WarningApiVersion { WarningApiVersion(rawValue: valueFor(name: "app.warningApiVersion") as? String ?? "") ?? .v1 }
    
    private var config: [[String: Any]] = [] {
        didSet { distributeUpdatedConfig() }
    }
    
    private var receivedData: [String: Data] = [:]
    private var completions: [String: RequestCompletion] = [:]
    
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.stopcovid.ios.ServerSDK-Config")
        backgroundConfiguration.timeoutIntervalForRequest = ServerConstant.timeout
        backgroundConfiguration.timeoutIntervalForResource = ServerConstant.timeout
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    
    public func start() {
        writeInitialFileIfNeeded()
        loadLocalConfig()
    }
    
    public func getDeviceParametersFor(model: String) -> DeviceParameters? {
        guard let deviceCalibration = valueFor(name: "ble.calibration") as? [[String: Any]] else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: deviceCalibration, options: []) else { return nil }
        let devicesParameters: [DeviceParameters] = (try? JSONDecoder().decode([DeviceParameters].self, from: data)) ?? []
        if let parameters = devicesParameters.filter({ $0.model == model }).first {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "iPhone" }).first, UIDevice.current.userInterfaceIdiom == .phone {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "iPad" }).first, UIDevice.current.userInterfaceIdiom == .pad {
            return parameters
        } else if let parameters = devicesParameters.filter({ $0.model == "DEFAULT" }).first {
            return parameters
        } else {
            let txAverage: Double = -15
            let rxAverage: Double = -5
            return DeviceParameters(model: "-", txFactor: txAverage, rxFactor: rxAverage)
        }
    }
    
    public func fetchConfig(_ completion: @escaping (_ result: Result<Double, Error>) -> ()) {
        let requestId: String = UUID().uuidString
        completions[requestId] = completion
        let task: URLSessionDataTask = session.dataTask(with: url)
        task.taskDescription = requestId
        task.resume()
    }
    
    private func loadLocalConfig() {
        guard let data = try? Data(contentsOf: localFileUrl()) else { return }
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else { return }
        self.config = json["config"] as? [[String: Any]] ?? []
    }
    
    private func valueFor(name: String) -> Any? {
        config.first { $0["name"] as? String == name }?["value"]
    }
    
    private func distributeUpdatedConfig() {
        RBManager.shared.proximitiesRetentionDurationInDays = dataRetentionPeriod
        RBManager.shared.preSymptomsSpan = preSymptomsSpan
        RBManager.shared.positiveSampleSpan = positiveSampleSpan
        if RBManager.shared.isProximityActivated {
            RBManager.shared.stopProximityDetection()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                RBManager.shared.startProximityDetection()
            }
        }
        refreshBackgroundFetchInterval()
    }
    
    private func refreshBackgroundFetchInterval() {
        if let checkStatusFrequency = checkStatusFrequency {
            let randomStatusHour: Double = self.randomStatusHour ?? 0.0
            let interval: Double = checkStatusFrequency * 3600.0 + (randomStatusHour == 0.0 ? 0.0 : Double.random(in: 0..<randomStatusHour * 3600.0))
            UIApplication.shared.setMinimumBackgroundFetchInterval(interval)
        }
    }
    
    private func writeInitialFileIfNeeded() {
        let fileUrl: URL = Bundle(for: ParametersManager.self).url(forResource: url.deletingPathExtension().lastPathComponent, withExtension: url.pathExtension)!
        let destinationFileUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent("config.json")
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
        }
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.svLibraryDirectory().appendingPathComponent("config")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
    private func localFileUrl() -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("config.json")
    }
    
}

extension ParametersManager: URLSessionDelegate, URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let requestId: String = dataTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if dataTask.response?.svIsError == true {
                let statusCode: Int = dataTask.response?.svStatusCode ?? 0
                let message: String = data.isEmpty ? "No logs received from the server" : (String(data: data, encoding: .utf8) ?? "Unknown error")
                completion(.failure(NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)))
                self.completions[dataTask.taskDescription ?? ""] = nil
            } else {
                var receivedData: Data = self.receivedData[requestId] ?? Data()
                receivedData.append(data)
                self.receivedData[requestId] = receivedData
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response!.svIsError == true {
                    let statusCode: Int = task.response?.svStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error" )
                    completion(.failure(NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)))
                    self.completions[task.taskDescription ?? ""] = nil
                } else {
                    do {
                        let json: [String: Any] = (try JSONSerialization.jsonObject(with: receivedData, options: [])) as? [String: Any] ?? [:]
                        guard !json.isEmpty else {
                            DispatchQueue.main.async {
                                completion(.failure(NSError.svLocalizedError(message: "Malformed json config. Using the last known version instead.", code: 0)))
                            }
                            return
                        }
                        try receivedData.write(to: self.localFileUrl())
                        self.config = json["config"] as? [[String: Any]] ?? []
                        DispatchQueue.main.async {
                            completion(.success(task.response!.serverTime))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            self.completions[task.taskDescription ?? ""] = nil
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: certificateFile) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
