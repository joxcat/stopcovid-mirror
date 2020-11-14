// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  PrivacyManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol PrivacyChangesObserver: class {
    
    func privacyChanged()
    
}

final class PrivacyObserverWrapper: NSObject {
    
    weak var observer: PrivacyChangesObserver?
    
    init(observer: PrivacyChangesObserver) {
        self.observer = observer
    }
    
}

final class PrivacyManager: RemoteFileSyncManager {

    static let shared: PrivacyManager = PrivacyManager()
    var privacySections: [PrivacySection] = []
    
    @UserDefault(key: .lastInitialPrivacyBuildNumber)
    private var lastInitialPrivacyBuildNumber: String? = nil
    
    @UserDefault(key: .lastPrivacyUpdateDate)
    private var lastUpdateDate: Date = .distantPast
    
    private var observers: [PrivacyObserverWrapper] = []
    
    override func canUpdateData() -> Bool {
        let now: Date = Date()
        let lastFetchIsTooOld: Bool = now.timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= RemoteFileConstant.minDurationBetweenUpdatesInSeconds
        let languageChanged: Bool = lastLanguageCode != Locale.currentLanguageCode
        return lastFetchIsTooOld || languageChanged
    }
    
    override func saveUpdatedAt() {
        self.lastUpdateDate = Date()
    }
    
    override func lastBuildNumber() -> String? { lastInitialPrivacyBuildNumber }
    override func saveLastBuildNumber(_ buildNumber: String) {
        lastInitialPrivacyBuildNumber = buildNumber
    }
    
    override func workingDirectoryName() -> String { "Privacy" }
    
    override func initialFileUrl(for languageCode: String) -> URL {
        Bundle.main.url(forResource: "privacy-\(languageCode)", withExtension: "json") ?? Bundle.main.url(forResource: "privacy-\(Constant.defaultLanguageCode)", withExtension: "json")!
    }
    
    override func localFileUrl(for languageCode: String) -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("privacy-\(languageCode).json")
    }
    
    override func remoteFileUrl(for languageCode: String) -> URL {
        URL(string: "\(RemoteFileConstant.baseUrl)/privacy-\(languageCode).json")!
    }
    
    override func processReceivedData(_ data: Data) -> Bool {
        do {
            privacySections = try JSONDecoder().decode([PrivacySection].self, from: data)
            return true
        } catch {
            return false
        }
    }
    
    override func notifyObservers() {
        observers.forEach { $0.observer?.privacyChanged() }
    }
    
}

extension PrivacyManager {
    
    func addObserver(_ observer: PrivacyChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(PrivacyObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: PrivacyChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: PrivacyChangesObserver) -> PrivacyObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
}
