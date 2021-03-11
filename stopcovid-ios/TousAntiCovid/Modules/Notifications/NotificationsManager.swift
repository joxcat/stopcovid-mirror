// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NotificationsManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit
import UserNotifications
import RobertSDK

final class NotificationsManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared: NotificationsManager = NotificationsManager()

    var waitingToReactivateProximity: Bool = false
    
    @UserDefault(key: .showNewInfoNotification)
    var showNewInfoNotification: Bool = true
    
    @UserDefault(key: .lastNotificationTimestamp)
    private var lastNotificationTimeStamp: Double = 0.0
    
    func start() {
        UNUserNotificationCenter.current().delegate = self
        addObservers()
    }

    func areNotificationsAuthorized(completion: ((_ authorized: Bool) -> ())? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion?(settings.alertSetting == .enabled)
            }
        }
    }

    func requestAuthorization(completion: ((_ granted: Bool) -> ())? = nil) {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, _) in
                DispatchQueue.main.async {
                    completion?(granted)
                }
            })
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.clearBadge()
        if response.notification.request.identifier == NotificationsContant.Identifier.proximityReactivation {
            if UIApplication.shared.applicationState == .active {
                NotificationCenter.default.post(name: .didTouchProximityReactivationNotification, object: nil)
            } else {
                waitingToReactivateProximity = true
            }
        }
        completionHandler()
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        if waitingToReactivateProximity {
            waitingToReactivateProximity = false
            NotificationCenter.default.post(name: .didTouchProximityReactivationNotification, object: nil)
        }
    }

    func scheduleNotification(minHour: Int?, maxHour: Int?, triggerDate: Date = Date(), title: String, body: String, identifier: String, badge: Int? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let badge = badge {
            content.badge = NSNumber(integerLiteral: badge)
        }
        var triggerDate: Date = triggerDate
        if let minHour = minHour, let maxHour = maxHour {
            var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let hour: Int = components.hour ?? 0
            if hour < minHour {
                components.hour = minHour
                components.minute = 0
                components.second = 0
                if let date = Calendar.current.date(from: components) {
                    triggerDate = date
                }
            } else if hour > maxHour {
                components.hour = minHour
                components.minute = 0
                components.second = 0
                if let date = Calendar.current.date(from: components)?.dateByAddingDays(1) {
                    triggerDate = date
                }
            }
        }
        let delay: Double = max(triggerDate.timeIntervalSince1970 - Date().timeIntervalSince1970, 0.0)
        let trigger: UNTimeIntervalNotificationTrigger? = delay == 0 ? nil : UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request: UNNotificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    func triggerRestartNotification() {
        checkIfNotificationIsAlreadySentOrStillVisible(for: NotificationsContant.Identifier.error) { alreadySentOrStillVisible in
            guard !alreadySentOrStillVisible else { return }
            let content = UNMutableNotificationContent()
            content.title = "notification.error.title".localized
            content.body = "notification.error.message".localized
            content.sound = .default
            let request: UNNotificationRequest = UNNotificationRequest(identifier: NotificationsContant.Identifier.error, content: content, trigger: nil)
            self.requestAuthorization { _ in
                UNUserNotificationCenter.current().add(request) { _ in }
            }
        }
    }
    
    func triggerGenericNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "(" + Date().fullDateFormatted() + ") " + body
        content.sound = .default
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }

    
    func triggerDeviceTimeErrorNotification() {
        checkIfNotificationIsAlreadySentOrStillVisible(for: NotificationsContant.Identifier.deviceTimeError) { alreadySentOrStillVisible in
            guard !alreadySentOrStillVisible else { return }
            let content = UNMutableNotificationContent()
            content.title = "common.error.clockNotAligned.title".localized
            content.body = "common.error.clockNotAligned.message".localized
            content.sound = .default
            let request: UNNotificationRequest = UNNotificationRequest(identifier: NotificationsContant.Identifier.deviceTimeError, content: content, trigger: nil)
            self.requestAuthorization { _ in
                UNUserNotificationCenter.current().add(request) { _ in }
            }
        }
    }

    func triggerProximityServiceRunningNotification(minHoursBetweenNotif: Int) {
        guard shouldShowNotification(minHoursBetweenNotif) else { return }
        let content = UNMutableNotificationContent()
        content.title = "notification.proximityServiceRunning.title".localized
        content.body = "notification.proximityServiceRunning.message".localized
        content.sound = .default
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }

    func triggerProximityServiceNotRunningNotification(minHoursBetweenNotif: Int) {
        guard shouldShowNotification(minHoursBetweenNotif) else { return }
        let content = UNMutableNotificationContent()
        content.title = "notification.proximityServiceNotRunning.title".localized
        content.body = "notification.proximityServiceNotRunning.message".localized
        content.sound = .default
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
    func triggerInfoCenterNewsAvailableNotification() {
        guard showNewInfoNotification else { return }
        guard UIApplication.shared.applicationState != .active else { return }
        let content = UNMutableNotificationContent()
        content.title = "info.notification.newsAvailable.title".localized
        content.body = "info.notification.newsAvailable.body".localized
        content.sound = .default
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
    func scheduleStillHavingFeverNotification(minHour: Int?, maxHour: Int?, triggerDate: Date) {
        scheduleNotification(minHour: minHour, maxHour: maxHour, triggerDate: triggerDate, title: "notification.stillHavingFever.title".localized, body: "notification.stillHavingFever.message".localized, identifier: NotificationsContant.Identifier.stillHavingFever)
    }
    
    func scheduleUltimateNotification(minHour: Int?, maxHour: Int?) {
        let content = UNMutableNotificationContent()
        content.title = "notification.ultimateStatus.title".localized
        content.body = "notification.ultimateStatus.message".localized
        content.sound = .default
        content.badge = 1
        let now: Date = Date()
        let targetedDate: Date = now.addingTimeInterval(3.0 * 24.0 * 3600.0)
        var triggerDate: Date = targetedDate
        if let minHour = minHour, let maxHour = maxHour {
            var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetedDate)
            let hour: Int = components.hour ?? 0
            if hour < minHour {
                components.hour = minHour
                components.minute = 0
                components.second = 0
                if let date = Calendar.current.date(from: components) {
                    triggerDate = date
                }
            } else if hour > maxHour {
                components.hour = minHour
                components.minute = 0
                components.second = 0
                if let date = Calendar.current.date(from: components)?.dateByAddingDays(1) {
                    triggerDate = date
                }
            }
        }
        let delay: Double = max(triggerDate.timeIntervalSince1970 - now.timeIntervalSince1970, 0.0)
        let trigger: UNTimeIntervalNotificationTrigger? = delay == 0 ? nil : UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request: UNNotificationRequest = UNNotificationRequest(identifier: NotificationsContant.Identifier.ultimate, content: content, trigger: trigger)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationsContant.Identifier.ultimate])
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [NotificationsContant.Identifier.ultimate])
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    func scheduleProximityReactivationNotification(hours: Double) {
        let content = UNMutableNotificationContent()
        content.title = "notification.reactivationReminder.title".localized
        content.body = "notification.reactivationReminder.body".localized
        content.sound = .default
        content.badge = 1
        let trigger: UNTimeIntervalNotificationTrigger? = UNTimeIntervalNotificationTrigger(timeInterval: hours * 3600.0, repeats: false)
        let request: UNNotificationRequest = UNNotificationRequest(identifier: NotificationsContant.Identifier.proximityReactivation, content: content, trigger: trigger)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationsContant.Identifier.proximityReactivation])
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [NotificationsContant.Identifier.proximityReactivation])
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    func cancelProximityReactivationNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationsContant.Identifier.proximityReactivation])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [NotificationsContant.Identifier.proximityReactivation])
    }
    
    func cancelStillHavingFeverNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationsContant.Identifier.stillHavingFever])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [NotificationsContant.Identifier.stillHavingFever])
    }
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func shouldShowNotification(_ minHoursBetweenNotif: Int) -> Bool {
        let timestamp: Double = Date().timeIntervalSince1970
        guard timestamp - lastNotificationTimeStamp > Double(minHoursBetweenNotif * 3600) else { return false }
        lastNotificationTimeStamp = timestamp
        return true
    }
    
    private func checkIfNotificationIsAlreadySentOrStillVisible(for identifier: String, completion: @escaping (_ alreadySentOrStillVisible: Bool) -> ()) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { pendingRequests in
            UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in
                let didFindMatchingPendingRequest: Bool = !pendingRequests.filter { $0.identifier == identifier }.isEmpty
                let didFindMatchingDeliveredNotification: Bool = !deliveredNotifications.filter { $0.request.identifier == identifier }.isEmpty
                completion(didFindMatchingPendingRequest || didFindMatchingDeliveredNotification)
            }
        }
    }

}
