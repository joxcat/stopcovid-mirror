// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NotificationsManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the STOP-COVID project.
//

import UIKit
import UserNotifications

final class NotificationsManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared: NotificationsManager = NotificationsManager()

    @UserDefault(key: .lastNotificationTimestamp)
    private var lastNotificationTimeStamp: Double  = 0.0

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func areNotificationsAuthorized(completion: ((_ authorized: Bool) -> ())? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion?(settings.alertSetting == .enabled)
            }
        }
    }

    func requestAuthorization(completion: ((_ granted: Bool) -> ())? = nil) {
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, _) in
            DispatchQueue.main.async {
                completion?(granted)
            }
        })
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == NotificationsContant.Identifier.atRisk {
            NotificationCenter.default.post(name: .didTouchAtRiskNotification, object: nil)
        }
        UIApplication.shared.clearBadge()
        completionHandler()
    }
    
    func scheduleAtRiskNotification(minHour: Int?, maxHour: Int?) {
        let content = UNMutableNotificationContent()
        content.title = "notification.atRisk.title".localized
        content.body = "notification.atRisk.message".localized
        content.sound = .default
        content.badge = 1
        let now: Date = Date()
        var triggerDate: Date = now
        if let minHour = minHour, let maxHour = maxHour {
            var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
            guard let hour = components.hour else { return }
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
        let request: UNNotificationRequest = UNNotificationRequest(identifier: NotificationsContant.Identifier.atRisk, content: content, trigger: trigger)
        requestAuthorization { _ in
            UNUserNotificationCenter.current().add(request) { _ in }
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
