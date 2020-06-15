// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AppDelegate.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 07/04/2020 - for the STOP-COVID project.
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initAppearance()
        initUrlCache()
        LocalizationsManager.shared.start()
        PrivacyManager.shared.start()
        OrientationManager.shared.start()
        if isOnboardingDone {
            BluetoothStateManager.shared.start()
        }
        RBManager.shared.start(isFirstInstall: !isAppAlreadyInstalled,
                               server: Server(baseUrl: Constant.Server.baseUrl,
                                              publicKey: Constant.Server.publicKey,
                                              certificateFile: Constant.Server.certificate,
                                              configUrl: Constant.Server.configUrl,
                                              deviceTimeNotAlignedToServerTimeDetected: {
                                    if UIApplication.shared.applicationState != .active {
                                        NotificationsManager.shared.triggerDeviceTimeErrorNotification()
                                    }
                               }),
                               storage: StorageManager(),
                               bluetooth: BluetoothManager(),
                               isAtRiskDidChangeHandler: { isAtRisk in
            if isAtRisk == true {
                NotificationsManager.shared.scheduleAtRiskNotification(minHour: ParametersManager.shared.minHourContactNotif, maxHour: ParametersManager.shared.maxHourContactNotif)
            }
        }, didStopProximityDueToLackOfEpochsHandler: {
            NotificationsManager.shared.triggerRestartNotification()
        })
        ParametersManager.shared.start()
        isAppAlreadyInstalled = true
        rootCoordinator.start()
        initAppMaintenance()
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.clearBadge()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        triggerStatusRequestIfNeeded { error in
            if let error = error, (error as NSError).code == -1 {
                NotificationsManager.shared.triggerDeviceTimeErrorNotification()
            }
        }
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        triggerStatusRequestIfNeeded() { error in
            completionHandler(error == nil ? .newData : .failed)
        }
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
    
    private func triggerStatusRequestIfNeeded(completion: ((_ error: Error?) -> ())? = nil) {
        if RBManager.shared.isRegistered {
            let lastStatusRequestTimestamp: Double = RBManager.shared.lastStatusReceivedDate?.timeIntervalSince1970 ?? 0.0
            let nowTimestamp: Double = Date().timeIntervalSince1970
            if nowTimestamp - lastStatusRequestTimestamp >= ParametersManager.shared.statusTimeInterval {
                RBManager.shared.status { error in
                    self.lastStatusBackgroundFetchTimestamp = Date().timeIntervalSince1970
                    self.lastStatusBackgroundFetchDidSucceed = error == nil
                    completion?(error)
                }
            } else {
                completion?(nil)
            }
        } else {
            completion?(nil)
        }
    }
    
}
