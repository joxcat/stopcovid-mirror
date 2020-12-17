// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AppDelegate.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/04/2020 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    private let rootCoordinator: RootCoordinator = RootCoordinator()
    
    @UserDefault(key: .isAppAlreadyInstalled)
    var isAppAlreadyInstalled: Bool = false
    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false
    

    private var lastStatusTriggerEventTimestamp: TimeInterval = 0.0
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initAppearance()
        initUrlCache()
        NotificationsManager.shared.start()
        LocalizationsManager.shared.start()
        InfoCenterManager.shared.start()
        KeyFiguresManager.shared.start()
        let storageManager: StorageManager = StorageManager()
        AttestationsManager.shared.start(storageManager: storageManager)
        VenuesManager.shared.start(storageManager: storageManager)
        IsolationManager.shared.start(storageManager: storageManager)
        if #available(iOS 14.0, *) {
            WidgetManager.shared.start()
        }
        PrivacyManager.shared.start()
        LinksManager.shared.start()
        KeyFiguresExplanationsManager.shared.start()
        OrientationManager.shared.start()
        if isOnboardingDone {
            BluetoothStateManager.shared.start()
        }
        
        WarningServer.shared.start(baseUrl: { Constant.Server.warningBaseUrl },
                                   certificateFile: Constant.Server.warningCertificate)
        
        RBManager.shared.start(isFirstInstall: !isAppAlreadyInstalled,
                               server: Server(baseUrl: { Constant.Server.baseUrl },
                                              publicKey: Constant.Server.publicKey,
                                              certificateFile: Constant.Server.certificate,
                                              configUrl: Constant.Server.configUrl,
                                              configCertificateFile: Constant.Server.resourcesCertificate,
                                              deviceTimeNotAlignedToServerTimeDetected: {
                                    if UIApplication.shared.applicationState != .active {
                                        NotificationsManager.shared.triggerDeviceTimeErrorNotification()
                                    }
                               }),
                               storage: storageManager,
                               bluetooth: BluetoothManager(),
                               filter: FilteringManager(),
                               isAtRiskDidChangeHandler: { isAtRisk in
            if isAtRisk == true {
                NotificationsManager.shared.scheduleAtRiskNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
            }
        }, didStopProximityDueToLackOfEpochsHandler: {
            self.triggerStatusRequestIfNeeded()
            NotificationsManager.shared.triggerRestartNotification()
        }, didReceiveProximityHandler: {
            self.triggerStatusRequestIfNeeded()
        }, didSaveProximity: { _ in })
        ParametersManager.shared.start()
        isAppAlreadyInstalled = true
        rootCoordinator.start()
        initAppMaintenance()
        DeepLinkingManager.shared.start()
        UIApplication.shared.registerForRemoteNotifications()
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            processShortcutItem(shortcutItem)
        }
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        processShortcutItem(shortcutItem)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        ConfigManager.shared.fetch { _ in
            self.updateAppShortcut()
        }
        UIApplication.shared.clearBadge()
        RBManager.shared.clearOldLocalProximities()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        triggerStatusRequestIfNeeded { error in
            if let error = error, (error as NSError).code == -1 {
                NotificationsManager.shared.triggerDeviceTimeErrorNotification()
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        RBManager.shared.stopProximityDetection()
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        triggerStatusRequestIfNeeded() { error in
            completionHandler(.newData)
        }
        InfoCenterManager.shared.fetchInfo()
        KeyFiguresManager.shared.fetchKeyFigures()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString: String = deviceToken.hexadecimalString()
        RBManager.shared.pushToken = deviceTokenString
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        triggerStatusRequestIfNeeded(showNotifications: true) { error in
            completionHandler(.newData)
        }
        InfoCenterManager.shared.fetchInfo()
        KeyFiguresManager.shared.fetchKeyFigures()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if #available(iOS 14.0, *) {
            WidgetManager.shared.processOpeningUrl(url)
        }
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if #available(iOS 14.0, *) {
            WidgetManager.shared.processUserActivity(userActivity)
        }
        DeepLinkingManager.shared.processActivity(userActivity)
        return true
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    private func initAppearance() {
        UINavigationBar.appearance().tintColor = Asset.Colors.tint.color
    }
    
    private func initUrlCache() {
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        URLSession.shared.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    }
    
    private func initAppMaintenance() {
        MaintenanceManager.shared.start(coordinator: rootCoordinator)
    }
    
    private func updateAppShortcut() {
        var shortcuts: [UIApplicationShortcutItem] = []
        if ParametersManager.shared.displayAttestation {
            let attestationShortcut: UIApplicationShortcutItem = UIApplicationShortcutItem(type: Constant.ShortcutItem.newAttestation.rawValue,
                                                                                           localizedTitle: Constant.ShortcutItem.newAttestation.rawValue.localized,
                                                                                           localizedSubtitle: nil,
                                                                                           icon: UIApplicationShortcutIcon(type: .compose))
            shortcuts.append(attestationShortcut)
        }
        if VenuesManager.shared.isVenuesRecordingActivated {
            let venuesShortcut: UIApplicationShortcutItem = UIApplicationShortcutItem(type: Constant.ShortcutItem.venues.rawValue,
                                                                                      localizedTitle: Constant.ShortcutItem.venues.rawValue.localized,
                                                                                      localizedSubtitle: nil,
                                                                                      icon: UIApplicationShortcutIcon(type: .capturePhoto))
            shortcuts.append(venuesShortcut)
        }
        UIApplication.shared.shortcutItems = shortcuts
    }

    func triggerStatusRequestIfNeeded(showNotifications: Bool = false, force: Bool = false, completion: ((_ error: Error?) -> ())? = nil) {
        let nowTimestamp: TimeInterval = Date().timeIntervalSince1970
        guard nowTimestamp - lastStatusTriggerEventTimestamp > Constant.secondsBeforeStatusRetry || force else {
            completion?(NSError.localizedError(message: "lastStatusTriggerEventTimestamp registered less than \(Int(Constant.secondsBeforeStatusRetry)) seconds ago", code: 0))
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
                case .v3, .v4:
                    RBManager.shared.statusV3 { error in
                        if showNotifications {
                            self.processStatusResponseNotification(error: error)
                        }
                        if error == nil {
                            NotificationsManager.shared.scheduleUltimateNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
                        }
                        completion?(error)
                    }
                    if VenuesManager.shared.isVenuesRecordingActivated {
                        VenuesManager.shared.status()
                    }
                }
            } else {
                if showNotifications && [.v3, .v4].contains(ParametersManager.shared.apiVersion) {
                    self.processStatusResponseNotification(error: nil)
                }
                let retryCriteria: String = "Current: \(Int(nowTimestamp - mostRecentResponseTimestamp)) | Expected: \(Int(ParametersManager.shared.minStatusRetryTimeInterval))"
                let timeCriteria: String = "Current: \(Int(nowTimestamp - lastStatusSuccessTimestamp)) | Expected: \(Int(ParametersManager.shared.statusTimeInterval))"
                completion?(NSError.localizedError(message: "Last status requested/received too recently:\n\n-----\nRetry\n-----\n\(retryCriteria)\n\n--------\nMin time\n--------\n\(timeCriteria)", code: 0))
            }
        } else {
            completion?(nil)
        }
    }

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
    
    private func processShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if shortcutItem.type == Constant.ShortcutItem.newAttestation.rawValue {
            DeepLinkingManager.shared.processAttestationUrl()
        } else if shortcutItem.type == Constant.ShortcutItem.venues.rawValue {
            DeepLinkingManager.shared.processFullVenueRecordingUrl()
        }
    }
    
}
