// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  DeepLinkingManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK

final class DeepLinkingManager {
    
    static let shared: DeepLinkingManager = DeepLinkingManager()
    weak var enterCodeController: EnterCodeController?
    
    weak var attestationController: AttestationsViewController?
    weak var venuesRecordingOnboardingController: VenuesRecordingOnboardingController?
    weak var flashVenueCodeController: FlashVenueCodeController?
    
    private var waitingNotification: Notification?
    
    func start() {
        addObservers()
    }
    
    func processActivity(_ activity: NSUserActivity) {
        guard activity.activityType == "NSUserActivityTypeBrowsingWeb" else { return }
        guard let url = activity.webpageURL else { return }
        processUrl(url)
    }
    
    func processAttestationUrl() {
        guard attestationController == nil else { return }
        let notification: Notification = Notification(name: .newAttestationFromDeeplink)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    func processFullVenueRecordingUrl() {
        let notification: Notification = Notification(name: .openFullVenueRecordingFlowFromDeeplink)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        guard let notification = waitingNotification else { return }
        NotificationCenter.default.post(notification)
        waitingNotification = nil
    }
    
    private func processUrl(_ url: URL) {
        if url.host == "tac.gouv.fr" {
            processVenueUrl(url)
        } else if url.path.hasPrefix("/app/code") {
            processCodeUrl(url)
        } else if url.path.hasPrefix("/app/attestation") {
            processAttestationUrl()
        }
    }
    
    private func processCodeUrl(_ url: URL) {
        guard RBManager.shared.isRegistered else { return }
        let code: String = url.path.replacingOccurrences(of: "/app/code/", with: "")
        let notification: Notification = Notification(name: .didEnterCodeFromDeeplink, object: code)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
    private func processVenueUrl(_ url: URL) {
        guard VenuesManager.shared.isVenueUrlValid(url) else {
            UIApplication.shared.keyWindow?.rootViewController?.topPresentedController.showAlert(title: "enterCodeController.alert.invalidCode.title".localized,
                                                                                                 message: "enterCodeController.alert.invalidCode.message".localized,
                                                                                                 okTitle: "common.ok".localized)
            return
        }
        guard !VenuesManager.shared.isVenueUrlExpired(url) else {
            UIApplication.shared.keyWindow?.rootViewController?.topPresentedController.showAlert(title: "enterCodeController.alert.expiredCode.title".localized,
                                                                                                 message: "enterCodeController.alert.expiredCode.message".localized,
                                                                                                 okTitle: "common.ok".localized)
            return
        }
        let notification: Notification = Notification(name: .newVenueRecordingFromDeeplink, object: url)
        guard UIApplication.shared.applicationState == .active else {
            waitingNotification = notification
            return
        }
        NotificationCenter.default.post(notification)
    }
    
}
