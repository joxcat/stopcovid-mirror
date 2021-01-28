// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenuesManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK
import StorageSDK
import ServerSDK

protocol VenuesChangesObserver: class {
    
    func venuesDidUpdate()
    
}

final class VenuesObserverWrapper: NSObject {
    
    weak var observer: VenuesChangesObserver?
    
    init(observer: VenuesChangesObserver) {
        self.observer = observer
    }
    
}

final class VenuesManager: NSObject {
    
    static let shared: VenuesManager = VenuesManager()
    
    var isVenuesRecordingActivated: Bool {
        ParametersManager.shared.displayRecordVenues
    }
    var isPrivateEventsActivated: Bool {
        ParametersManager.shared.displayPrivateEvent
    }
    var venuesQrCodes: [VenueQrCode] { storageManager?.venuesQrCodes() ?? [] }
    var isAtWarningRisk: Bool { lastWarningRiskReceivedDate != nil }
    var lastWarningRiskReceivedDate: Date? {
        get {
            storageManager.lastWarningRiskReceivedDate()
        }
        set {
            let wasRiskAlreadyExisting: Bool = lastWarningRiskReceivedDate != nil
            if newValue == nil {
                storageManager.saveCurrentWarningRiskScoringDate(nil)
            } else if !wasRiskAlreadyExisting {
                NotificationsManager.shared.scheduleAtWarningRiskNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
                storageManager.saveCurrentWarningRiskScoringDate(newValue)
            }
            storageManager.saveLastWarningRiskReceivedDate(newValue)
        }
    }
    var needPrivateEventQrCodeGeneration: Bool {
        let now: Date = Date()
        let currentQrCodeDate: Date = self.currentQrCodeDate ?? .distantPast
        return !Calendar.current.isDate(now, inSameDayAs: currentQrCodeDate)
    }
    var currentQrCodeImage: UIImage? { UIImage(data: VenuesManager.shared.currentQrCodeData ?? Data()) }
    
    private var storageManager: StorageManager!
    private var observers: [VenuesObserverWrapper] = []
    private var didAlreadyRetryReport: Bool = false
    
    @UserDefault(key: .didAlreadySeeVenuesRecordingOnboarding)
    private var didAlreadySeeOnboarding: Bool = false
    
    @UserDefault(key: .venuesFeaturedWasActivatedAtLeastOneTime)
    private var venuesFeaturedWasActivatedAtLeastOneTime: Bool = false
    
    @OptionalUserDefault(key: .privateEventQrCodeString)
    private(set) var currentQrCodeString: String?
    @OptionalUserDefault(key: .privateEventQrCodeData)
    private(set) var currentQrCodeData: Data?
    @OptionalUserDefault(key: .privateEventQrCodeDate)
    private var currentQrCodeDate: Date?
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        addObserver()
    }
    
    func clearAllData() {
        storageManager.deleteVenuesQrCodeData()
        didAlreadySeeOnboarding = false
        venuesFeaturedWasActivatedAtLeastOneTime = false
        currentQrCodeString = nil
        currentQrCodeData = nil
        currentQrCodeDate = nil
    }
    
    func deleteVenueQrCode(_ venueQrCode: VenueQrCode) {
        storageManager.deleteVenueQrCode(venueQrCode)
    }
    
    func clearExpiredData() {
        storageManager.deleteExpiredVenuesQrCodeData(durationInSeconds: Double(ParametersManager.shared.venuesRetentionPeriod) * 24.0 * 3600.0)
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(venuesStorageDidUpdate), name: .venueQrCodeDataDidChange, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        clearExpiredData()
        retryReportIfNeeded()
    }
    
    @objc private func venuesStorageDidUpdate() {
        notifyObservers()
    }

}

extension VenuesManager {
    
    func addObserver(_ observer: VenuesChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(VenuesObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: VenuesChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: VenuesChangesObserver) -> VenuesObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.venuesDidUpdate() }
    }
    
}

// MARK: - Deeplinking -
extension VenuesManager {

    func isVenueUrlExpired(_ url: URL) -> Bool {
        guard url.host == "tac.gouv.fr" else { return true }
        let path: String = String(url.path.dropFirst(1))
        let info: [String] = path.components(separatedBy: "/")

        // Values
        guard let qrType = Int(info.item(at: 0) ?? "") else { return true }
        guard let uuid = info.item(at: 1) else { return true }
        guard let venueType = info.item(at: 2)?.uppercased() else { return true }
        let venueCategory: Int = Int(info.item(at: 3) ?? "") ?? 0
        let venueCapacity: Int = Int(info.item(at: 4) ?? "") ?? 0
        let timestamp: Double = Double(info.item(at: 5) ?? "") ?? Date().timeIntervalSince1970

        // Conditions
        guard [0, 1].contains(qrType) else { return true }
        guard uuid.isUuidCode else { return true }
        guard (1...3).contains(venueType.count) else { return true }
        guard (0...5).contains(venueCategory) else { return true }
        guard (0...).contains(venueCapacity) else { return true }
        
        let validityDuration: Double = Double(ParametersManager.shared.venuesRetentionPeriod) * 24.0 * 3600.0
        return Date().timeIntervalSince1970 - timestamp >= validityDuration
    }
    
    @discardableResult
    func processVenueUrl(_ url: URL) -> Bool {
        guard url.host == "tac.gouv.fr" else { return false }
        let path: String = String(url.path.dropFirst(1))
        let info: [String] = path.components(separatedBy: "/")

        // Values
        guard let qrType = Int(info.item(at: 0) ?? "") else { return false }
        guard let uuid = info.item(at: 1) else { return false }
        guard let venueType = info.item(at: 2)?.uppercased() else { return false }
        let venueCategory: Int = Int(info.item(at: 3) ?? "") ?? 0
        let venueCapacity: Int = Int(info.item(at: 4) ?? "") ?? 0
        let timestamp: Double = Double(info.item(at: 5) ?? "") ?? Date().timeIntervalSince1970

        // Conditions
        guard [0, 1].contains(qrType) else { return false }
        guard uuid.isUuidCode else { return false }
        guard (1...3).contains(venueType.count) else { return false }
        guard (0...5).contains(venueCategory) else { return false }
        guard (0...).contains(venueCapacity) else { return false }
        
        let date: Date = Date(timeIntervalSince1970: timestamp)
        let nowRoundedNtpTimestamp: Int = date.roundedTimeIntervalSince1900(interval: ParametersManager.shared.venuesTimestampRoundingInterval)
        
        let id: String
        if venueType == ParametersManager.shared.privateEventVenueType {
            id = "\(uuid)"
        } else {
            id = "\(uuid)\(nowRoundedNtpTimestamp)"
        }

        let maxSalt: Int = ParametersManager.shared.venuesSalt
        let salt: Int = (1...maxSalt).randomElement() ?? 0
        let payload: String = "\(salt)\(uuid)".sha256()

        let venueQrCode: VenueQrCode = VenueQrCode(id: id,
                                                   uuid: uuid,
                                                   qrType: qrType,
                                                   venueType: venueType,
                                                   ntpTimestamp: nowRoundedNtpTimestamp,
                                                   venueCategory: venueCategory > 0 ? venueCategory : nil,
                                                   venueCapacity: venueCapacity > 0 ? venueCapacity : nil,
                                                   payload: payload)
        storageManager.saveVenueQrCode(venueQrCode)
        return true
    }
    
    func venueTypeFrom(url: URL) -> String {
        let path: String = String(url.path.dropFirst(1))
        let info: [String] = path.components(separatedBy: "/")
        let venueType = info.item(at: 2) ?? ""
        return venueType
    }
    
    func generateNewPrivateEventQrCode() {
        let urlString: String = "https://tac.gouv.fr/0/\(UUID().uuidString.lowercased())/\(ParametersManager.shared.privateEventVenueType)"
        let date: Date = Date()
        guard let qrCode = urlString.qrCode() else { return }
        guard let qrCodeData = UIGraphicsImageRenderer(size: qrCode.size, format: qrCode.imageRendererFormat).image(actions: { _ in
            UIImage(ciImage: qrCode.ciImage!).draw(in: CGRect(origin: .zero, size: qrCode.size))
        }).pngData() else { return }
        currentQrCodeString = urlString
        currentQrCodeData = qrCodeData
        currentQrCodeDate = date
        guard let url = URL(string: urlString) else { return }
        processVenueUrl(url)
    }

}

// MARK: - Server requests -
extension VenuesManager {
    
    func status(_ completion: ((_ error: Error?) -> ())? = nil) {
        let now: Date = Date()
        let qrCodes: [VenueQrCode] = venuesQrCodes.filter { $0.ntpTimestamp <= now.timeIntervalSince1900 }
        guard !qrCodes.isEmpty else {
            completion?(nil)
            return
        }
        let staticQrCodePayloads: [(String, Int)] = qrCodes.filter { $0.qrType == VenueQrCode.QrCodeType.static.rawValue }.map { ($0.payload, $0.ntpTimestamp) }
        let dynamicQrCodePayloads: [(String, Int)] = qrCodes.filter { $0.qrType == VenueQrCode.QrCodeType.dynamic.rawValue }.map { ($0.payload, $0.ntpTimestamp) }
        WarningServer.shared.wstatus(staticQrCodePayloads: staticQrCodePayloads,
                                     dynamicQrCodePayloads: dynamicQrCodePayloads) { result in
            switch result {
            case let .success(isAtWarningRisk):
                self.lastWarningRiskReceivedDate = isAtWarningRisk ? Date() : nil
                completion?(nil)
            case let .failure(error):
                completion?(error)
            }
        }
    }

    func report(_ completion: ((_ error: Error?) -> ())? = nil) {
        guard let token = RBManager.shared.reportToken else {
            completion?(nil)
            return
        }
        let now: Date = Date()
        let qrCodes: [VenueQrCode] = venuesQrCodes.filter { $0.ntpTimestamp <= now.timeIntervalSince1900 }
        guard !qrCodes.isEmpty else {
            completion?(nil)
            return
        }
        let origin: Date = RBManager.shared.reportDataOriginDate ?? .distantPast
        let filteredQrCodes: [VenueQrCode] = qrCodes.filter { $0.ntpTimestamp >= origin.timeIntervalSince1900 }
        WarningServer.shared.wreport(token: token, visits: filteredQrCodes.map { $0.toWarningServerVisit() }) { error in
            if let error = error {
                guard (error as NSError).code != 403 else {
                    self.didAlreadyRetryReport = false
                    self.storageManager.deleteVenuesQrCodeData()
                    RBManager.shared.reportToken = nil
                    completion?(error)
                    return
                }
                if self.didAlreadyRetryReport {
                    self.didAlreadyRetryReport = false
                    completion?(error)
                } else {
                    self.didAlreadyRetryReport = true
                    self.report(completion)
                }
            } else {
                self.didAlreadyRetryReport = false
                self.storageManager.deleteVenuesQrCodeData()
                RBManager.shared.reportToken = nil
                completion?(nil)
            }
        }
    }

    private func retryReportIfNeeded() {
        guard RBManager.shared.reportToken != nil else {
            if RBManager.shared.isSick, !venuesQrCodes.isEmpty {
                storageManager.deleteVenuesQrCodeData()
            }
            return
        }
        guard !venuesQrCodes.isEmpty else {
            RBManager.shared.reportToken = nil
            return
        }
        report()
    }

}
