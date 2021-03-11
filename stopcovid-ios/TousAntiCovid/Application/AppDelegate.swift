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
    
    private var backgroundFetchCompletionId: String?
    private var remoteNotificationCompletionId: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initAppearance()
        initUrlCache()
        NotificationsManager.shared.start()
        LocalizationsManager.shared.start()
        InfoCenterManager.shared.start()
        KeyFiguresManager.shared.start()
        VaccinationCenterManager.shared.start()
        RisksUIManager.shared.start()
        let storageManager: StorageManager = StorageManager()
        AttestationsManager.shared.start(storageManager: storageManager)
        VenuesManager.shared.start(storageManager: storageManager)
        IsolationManager.shared.start(storageManager: storageManager)
        PrivacyManager.shared.start()
        LinksManager.shared.start()
        KeyFiguresExplanationsManager.shared.start()
        OrientationManager.shared.start()
        if isOnboardingDone {
            BluetoothStateManager.shared.start()
        }
        
        WarningServer.shared.start(baseUrl: { Constant.Server.warningBaseUrl },
                                   certificateFile: Constant.Server.warningCertificate,
                                   requestLoggingHandler: { task, responseData, error in })
        
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
                                              }, requestLoggingHandler: { task, responseData, error in }),
                               storage: storageManager,
                               bluetooth: BluetoothManager(),
                               filter: FilteringManager(),
                               didStopProximityDueToLackOfEpochsHandler: {
                                    StatusManager.shared.status()
                                    NotificationsManager.shared.triggerRestartNotification()
                               }, didReceiveProximityHandler: {
                                    StatusManager.shared.status()
                               }, didSaveProximity: { proximity in })
        ParametersManager.shared.start()
        if #available(iOS 14.0, *) {
            WidgetManager.shared.start()
        }
        StatusManager.shared.start()
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
        StatusManager.shared.status { error in
            if let error = error, (error as NSError).code == -1 {
                NotificationsManager.shared.triggerDeviceTimeErrorNotification()
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        RBManager.shared.stopProximityDetection()
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let uuid: String = UUID().uuidString
        backgroundFetchCompletionId = uuid
        StatusManager.shared.status() { error in
            if self.backgroundFetchCompletionId == uuid {
                self.backgroundFetchCompletionId = nil
                completionHandler(.newData)
            }
        }
        InfoCenterManager.shared.fetchInfo()
        KeyFiguresManager.shared.fetchKeyFigures()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString: String = deviceToken.hexadecimalString()
        RBManager.shared.pushToken = deviceTokenString
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let uuid: String = UUID().uuidString
        remoteNotificationCompletionId = uuid
        StatusManager.shared.status(showNotifications: true) { error in
            if self.remoteNotificationCompletionId == uuid {
                self.remoteNotificationCompletionId = nil
                completionHandler(.newData)
            }
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
    
    private func processShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if shortcutItem.type == Constant.ShortcutItem.newAttestation.rawValue {
            DeepLinkingManager.shared.processAttestationUrl()
        } else if shortcutItem.type == Constant.ShortcutItem.venues.rawValue {
            DeepLinkingManager.shared.processFullVenueRecordingUrl()
        }
    }

}
