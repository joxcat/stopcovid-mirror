// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MaintenanceManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/05/2020 - for the TousAntiCovid project.
//


import UIKit
import ServerSDK

final class MaintenanceManager: NSObject {

    static let shared: MaintenanceManager = MaintenanceManager()
    private var coordinator: MaintenanceSupportingCoordinator!
    private var maintenanceWindow: UIWindow?
    private let maxTries: Int = 2
    private var triesCount: Int = 0
    
    private var lastUpdateDate: Date = .distantPast
    
    override private init() {}
    
    func start(coordinator: MaintenanceSupportingCoordinator) {
        self.coordinator = coordinator
        addObserver()
    }
    
    func checkMaintenanceState(_ completion: (() -> ())? = nil) {
        var request: URLRequest = URLRequest(url: MaintenanceConstant.fileUrl)
        request.httpMethod = "GET"
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let task: URLSessionDataTask = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.processCheckError(error: error, completion: completion)
                } else {
                    guard let data = data else {
                        let error: Error = NSError.localizedError(message: "No data received for app maintenance", code: 400)
                        self.processCheckError(error: error, completion: completion)
                        return
                    }
                    do {
                        let json: [String: Any] = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
                        let iOSJson: [String: Any] = json["iOS"] as? [String: Any] ?? [:]
                        let iOSData: Data = try JSONSerialization.data(withJSONObject: iOSJson, options: [])
                        let info: MaintenanceInfo = try JSONDecoder().decode(MaintenanceInfo.self, from: iOSData)
                        self.triesCount = 0
                        if info.shouldShow() {
                            self.showController(info: info)
                        } else {
                            self.hideController()
                        }
                        self.lastUpdateDate = Date()
                        completion?()
                    } catch {
                        self.processCheckError(error: error, completion: completion)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func processCheckError(error: Error, completion: (() -> ())?) {
        triesCount += 1
        if triesCount < maxTries {
            checkMaintenanceState(completion)
        } else {
            triesCount = 0
            completion?()
        }
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        guard canUpdateMaintenanceInfo() else { return }
        checkMaintenanceState()
    }
    
    private func showController(info: MaintenanceInfo) {
        coordinator.showMaintenance(info: info)
    }
    
    private func hideController() {
        coordinator.hideMaintenance()
    }
    
    private func canUpdateMaintenanceInfo() -> Bool {
        let now: Date = Date()
        return now.timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= MaintenanceConstant.minDurationBetweenUpdatesInSeconds
    }
    
}

extension MaintenanceManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
