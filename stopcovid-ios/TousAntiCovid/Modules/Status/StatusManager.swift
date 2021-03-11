// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  StatusManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/02/2021 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK
import ServerSDK
import StorageSDK

protocol StatusChangesObserver: class {
    
    func statusRiskLevelDidChange()
    
}

final class StatusObserverWrapper: NSObject {
    
    weak var observer: StatusChangesObserver?
    
    init(observer: StatusChangesObserver) {
        self.observer = observer
    }
    
}

final class StatusManager {
    
    static let shared: StatusManager = StatusManager()
    
    @UserDefault(key: .hideStatus)
    var hideStatus: Bool = false {
        didSet { notifyStatusChange() }
    }
    
    var currentStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { RBManager.shared.currentStatusRiskLevel }
        set {
            if currentStatusRiskLevel?.riskLevel != newValue?.riskLevel {
                hideStatus = false
            }
            RBManager.shared.currentStatusRiskLevel = newValue
        }
    }
    
    var lastRobertStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { RBManager.shared.lastRobertStatusRiskLevel }
        set { RBManager.shared.lastRobertStatusRiskLevel = newValue }
    }
    
    var lastWarningStatusRiskLevel: RBStatusRiskLevelInfo? {
        get { RBManager.shared.lastWarningStatusRiskLevel }
        set { RBManager.shared.lastWarningStatusRiskLevel = newValue }
    }
    
    var isAtRisk: Bool { currentStatusRiskLevel?.riskLevel ?? 0.0 >= ParametersManager.shared.isolationMinRiskLevel }
    
    private let statusModelVersion: Int = 1
    
    @UserDefault(key: .currentStatusModelVersion)
    private var currentStatusModelVersion: Int = 0
    
    private var lastStatusTriggerEventTimestamp: TimeInterval = 0.0
    private var mustNotifyLastRiskLevelChange: Bool = false
    private var mustShowAlertAboutLastRiskLevelChange: Bool = false
    private var observers: [StatusObserverWrapper] = []
    
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        migrateOldAtRiskIfNeeded()
    }
    
    func status(showNotifications: Bool = false, force: Bool = false, completion: ((_ error: Error?) -> ())? = nil) {
        triggerStatusRequestIfNeeded(showNotifications: showNotifications, force: force) { statusResult in
            switch statusResult {
            case let .success(statusInfo):
                guard let statusInfo = statusInfo else {
                    completion?(nil)
                    return
                }
                self.triggerWarningStatusRequestIfNeeded { wstatusResult in
                    switch wstatusResult {
                    case let .success(wstatusInfo):
                        self.processReceivedStatusInfo(statusInfo: statusInfo, wstatusInfo: wstatusInfo)
                        completion?(nil)
                    case let .failure(error):
                        completion?(error)
                    }
                }
            case let .failure(error):
                completion?(error)
            }
        }
    }
    
}

extension StatusManager {

    func addObserver(_ observer: StatusChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(StatusObserverWrapper(observer: observer))
    }

    func removeObserver(_ observer: StatusChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }

    private func observerWrapper(for observer: StatusChangesObserver) -> StatusObserverWrapper? {
        observers.first { $0.observer === observer }
    }

    private func notifyObservers() {
        observers.forEach { $0.observer?.statusRiskLevelDidChange() }
    }

}

// MARK: - Migration management -
extension StatusManager {

    private func migrateOldAtRiskIfNeeded() {
        guard currentStatusModelVersion != statusModelVersion else { return }
        currentStatusModelVersion = statusModelVersion
        guard currentStatusRiskLevel == nil else { return }
        guard let lastRiskReceivedDate = RBManager.shared.lastRiskReceivedDate else {
            if RBManager.shared.lastStatusReceivedDate != nil {
                currentStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 0.0, lastContactDate: nil, lastRiskScoringDate: nil)
            }
            return
        }
        let periodEndDate: Date = lastRiskReceivedDate.dateByAddingDays(ParametersManager.shared.quarantinePeriod)
        let now: Date = Date()
        if now < periodEndDate {
            currentStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 4.0, lastContactDate: lastRiskReceivedDate, lastRiskScoringDate: nil)
        } else {
            currentStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 0.0, lastContactDate: nil, lastRiskScoringDate: nil)
        }
        RBManager.shared.lastRiskReceivedDate = nil
    }

}

// MARK: - Status triggering requests -
extension StatusManager {
    
    private func triggerStatusRequestIfNeeded(showNotifications: Bool = false, force: Bool = false, completion: ((_ result: Result<RBStatusRiskLevelInfo?, Error>) -> ())? = nil) {
        let nowTimestamp: TimeInterval = Date().timeIntervalSince1970
        guard nowTimestamp - lastStatusTriggerEventTimestamp > Constant.secondsBeforeStatusRetry || force else {
            let error: Error = NSError.localizedError(message: "lastStatusTriggerEventTimestamp registered less than \(Int(Constant.secondsBeforeStatusRetry)) seconds ago", code: 0)
            completion?(.failure(error))
            return
        }
        self.lastStatusTriggerEventTimestamp = nowTimestamp
        if RBManager.shared.isRegistered {
            let lastStatusErrorTimestamp: Double = RBManager.shared.lastStatusErrorDate?.timeIntervalSince1970 ?? 0.0
            let lastStatusSuccessTimestamp: Double = RBManager.shared.lastStatusReceivedDate?.timeIntervalSince1970 ?? 0.0
            let mostRecentResponseTimestamp: Double = max(lastStatusErrorTimestamp, lastStatusSuccessTimestamp)
            let nowTimestamp: Double = Date().timeIntervalSince1970
            if (nowTimestamp - mostRecentResponseTimestamp >= ParametersManager.shared.minStatusRetryTimeInterval && nowTimestamp - lastStatusSuccessTimestamp >= ParametersManager.shared.statusTimeInterval) || force {
                switch ParametersManager.shared.apiVersion {
                case .v5:
                    RBManager.shared.status { result in
                        switch result {
                        case let .success(info):
                            if showNotifications {
                                self.processStatusResponseNotification(error: nil)
                            }
                            NotificationsManager.shared.scheduleUltimateNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
                            completion?(.success(info))
                        case let .failure(error):
                            if showNotifications {
                                self.processStatusResponseNotification(error: error)
                            }
                            completion?(.failure(error))
                        }
                    }
                }
            } else {
                if showNotifications {
                    self.processStatusResponseNotification(error: nil)
                }
                let retryCriteria: String = "Current: \(Int(nowTimestamp - mostRecentResponseTimestamp)) | Expected: \(Int(ParametersManager.shared.minStatusRetryTimeInterval))"
                let timeCriteria: String = "Current: \(Int(nowTimestamp - lastStatusSuccessTimestamp)) | Expected: \(Int(ParametersManager.shared.statusTimeInterval))"
                let error: Error = NSError.localizedError(message: "Last status requested/received too recently:\n\n-----\nRetry\n-----\n\(retryCriteria)\n\n--------\nMin time\n--------\n\(timeCriteria)", code: 0)
                completion?(.failure(error))
            }
        } else {
            completion?(.success(nil))
        }
    }
    
    private func triggerWarningStatusRequestIfNeeded(_ completion: ((_ result: Result<RBStatusRiskLevelInfo?, Error>) -> ())? = nil) {
        let now: Date = Date()
        let qrCodes: [VenueQrCode] = VenuesManager.shared.venuesQrCodes.filter { $0.ntpTimestamp <= now.timeIntervalSince1900 }
        guard !qrCodes.isEmpty else {
            completion?(.success(nil))
            return
        }
        let staticQrCodePayloads: [(String, Int)] = qrCodes.filter { $0.qrType == VenueQrCode.QrCodeType.static.rawValue }.map { ($0.payload, $0.ntpTimestamp) }
        let dynamicQrCodePayloads: [(String, Int)] = qrCodes.filter { $0.qrType == VenueQrCode.QrCodeType.dynamic.rawValue }.map { ($0.payload, $0.ntpTimestamp) }
        WarningServer.shared.wstatus(staticQrCodePayloads: staticQrCodePayloads,
                                     dynamicQrCodePayloads: dynamicQrCodePayloads) { result in
            switch result {
            case let .success(info):
                completion?(.success(info))
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
}

// MARK: - Status response processing -
extension StatusManager {
    
    private func processStatusResponseNotification(error: Error?) {
        let minHoursBetweenNotif: Int = ParametersManager.shared.minHoursBetweenVisibleNotif
        if error != nil {
            NotificationsManager.shared.triggerRestartNotification()
        } else {
            guard ParametersManager.shared.pushDisplayAll else { return }
            if RBManager.shared.isProximityActivated {
                guard ParametersManager.shared.pushDisplayOnSuccess else { return }
                NotificationsManager.shared.triggerProximityServiceRunningNotification(minHoursBetweenNotif: minHoursBetweenNotif)
            } else {
                NotificationsManager.shared.triggerProximityServiceNotRunningNotification(minHoursBetweenNotif: minHoursBetweenNotif)
            }
        }
    }
    
    private func processReceivedStatusInfo(statusInfo: RBStatusRiskLevelInfo, wstatusInfo: RBStatusRiskLevelInfo?) {
        if statusInfo.lastRiskScoringDate == nil || lastRobertStatusRiskLevel?.lastRiskScoringDate == nil || statusInfo.lastRiskScoringDate ?? .distantPast > lastRobertStatusRiskLevel?.lastRiskScoringDate ?? .distantPast {
            lastRobertStatusRiskLevel = statusInfo
        }
        if let wstatusInfo = wstatusInfo {
            if wstatusInfo.lastRiskScoringDate == nil || lastWarningStatusRiskLevel?.lastRiskScoringDate == nil || wstatusInfo.lastRiskScoringDate ?? .distantPast > lastWarningStatusRiskLevel?.lastRiskScoringDate ?? .distantPast {
                lastWarningStatusRiskLevel = wstatusInfo
            }
        } else {
            lastWarningStatusRiskLevel = RBStatusRiskLevelInfo(riskLevel: 0.0, lastContactDate: nil, lastRiskScoringDate: nil)
        }

        let newStatus: [RBStatusRiskLevelInfo] = [lastRobertStatusRiskLevel, lastWarningStatusRiskLevel].compactMap { $0 }
        var newRiskLevelInfo: RBStatusRiskLevelInfo = newStatus.max(\.riskLevel)!
        if RisksUIManager.shared.level(for: newRiskLevelInfo.riskLevel) == nil {
            newRiskLevelInfo.riskLevel = 0.0
        }

        if !RBManager.shared.isSick {
            mustNotifyLastRiskLevelChange = (newRiskLevelInfo.riskLevel > currentStatusRiskLevel?.riskLevel ?? 0.0) || (newRiskLevelInfo.riskLevel != 0.0 && newRiskLevelInfo.riskLevel == currentStatusRiskLevel?.riskLevel && newRiskLevelInfo.lastRiskScoringDate ?? .distantPast > currentStatusRiskLevel?.lastRiskScoringDate ?? .distantPast)
            mustShowAlertAboutLastRiskLevelChange = newRiskLevelInfo.lastRiskScoringDate != currentStatusRiskLevel?.lastRiskScoringDate
        }

        currentStatusRiskLevel = newRiskLevelInfo
        showRiskLevelUpdateNotificationIfNeeded()
        if UIApplication.shared.applicationState == .active {
            showRiskLevelUpdateAlertIfNeeded()
        }

        notifyStatusChange()
    }
    
    private func notifyStatusChange() {
        NotificationCenter.default.post(name: .statusDataDidChange, object: nil)
        notifyObservers()
    }
    
}

// MARK: - Status update notifications -
extension StatusManager {
    
    @objc private func appDidBecomeActive() {
        showRiskLevelUpdateAlertIfNeeded()
    }
    
    private func showRiskLevelUpdateNotificationIfNeeded() {
        guard !RBManager.shared.isSick else { return }
        guard mustNotifyLastRiskLevelChange else { return }
        mustNotifyLastRiskLevelChange = false
        NotificationsManager.shared.scheduleNotification(minHour: ParametersManager.shared.minHourContactNotif,
                                                         maxHour: ParametersManager.shared.maxHourContactNotif,
                                                         title: RisksUIManager.shared.currentLevel?.labels.notifTitle?.localized ?? "",
                                                         body: RisksUIManager.shared.currentLevel?.labels.notifBody?.localizedOrEmpty ?? "",
                                                         identifier: NotificationsContant.Identifier.atRisk,
                                                         badge: 1)
    }
    
    private func showRiskLevelUpdateAlertIfNeeded() {
        guard !RBManager.shared.isSick else { return }
        guard mustShowAlertAboutLastRiskLevelChange else { return }
        mustShowAlertAboutLastRiskLevelChange = false
        guard let title = RisksUIManager.shared.currentLevel?.labels.notifTitle else { return }
        guard let message = RisksUIManager.shared.currentLevel?.labels.notifBody else { return }
        UIApplication.shared.keyWindow?.rootViewController?.topPresentedController.showAlert(title: title.localized,
                                                                                             message: message.localized,
                                                                                             okTitle: "common.ok".localized)
    }
    
}
