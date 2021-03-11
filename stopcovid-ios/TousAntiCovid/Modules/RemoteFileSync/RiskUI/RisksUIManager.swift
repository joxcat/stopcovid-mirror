// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RisksUIManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 23/02/2021 - for the TousAntiCovid project.
//

import Foundation

protocol RisksUIChangesObserver: class {
    
    func risksUIChanged()
    
}

final class RisksUIObserverWrapper: NSObject {
    
    weak var observer: RisksUIChangesObserver?
    
    init(observer: RisksUIChangesObserver) {
        self.observer = observer
    }
    
}

final class RisksUIManager: RemoteFileSyncManager {

    static let shared: RisksUIManager = RisksUIManager()
    
    var currentLevel: RisksUILevel? {
        guard let level = StatusManager.shared.currentStatusRiskLevel?.riskLevel else { return nil }
        return self.level(for: level)
    }

    var lastContactDateFrom: Date? {
        guard let contactDateFormatType = currentLevel?.contactDateFormatType else { return nil }
        guard contactDateFormatType != .none else { return nil }
        switch contactDateFormatType {
        case .date:
            return StatusManager.shared.currentStatusRiskLevel?.lastContactDate
        case .range, .none:
            return StatusManager.shared.currentStatusRiskLevel?.lastContactDate?.dateByAddingDays(-1)
        }
    }

    var lastContactDateTo: Date? {
        guard let contactDateFormatType = currentLevel?.contactDateFormatType else { return nil }
        guard contactDateFormatType != .none else { return nil }
        switch contactDateFormatType {
        case .date:
            return nil
        case .range, .none:
            return StatusManager.shared.currentStatusRiskLevel?.lastContactDate?.dateByAddingDays(1)
        }
    }

    private(set) var levels: [RisksUILevel] = []

    @UserDefault(key: .lastInitialRiskLevelsBuildNumber)
    private var lastInitialRiskLevelsBuildNumber: String? = nil
    
    @UserDefault(key: .lastRiskLevelsUpdateDate)
    private var lastUpdateDate: Date = .distantPast
    
    private var observers: [RisksUIObserverWrapper] = []
    
    override func start() {
        super.start()
        StatusManager.shared.addObserver(self)
    }
    
    func level(for level: Double) -> RisksUILevel? { levels.filter { $0.riskLevel == level }.first }
    
    override func canUpdateData() -> Bool {
        Date().timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= RemoteFileConstant.minDurationBetweenUpdatesInSeconds
    }
    
    override func saveUpdatedAt() {
        self.lastUpdateDate = Date()
    }
    
    override func lastBuildNumber() -> String? { lastInitialRiskLevelsBuildNumber }
    override func saveLastBuildNumber(_ buildNumber: String) {
        lastInitialRiskLevelsBuildNumber = buildNumber
    }
    
    override func workingDirectoryName() -> String { "RisksUI" }
    
    override func initialFileUrl(for languageCode: String) -> URL {
        Bundle.main.url(forResource: "risks", withExtension: "json")!
    }
    
    override func localFileUrl(for languageCode: String) -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("risks.json")
    }
    
    override func remoteFileUrl(for languageCode: String) -> URL {
        URL(string: "\(RisksUIConstant.baseUrl)/risks.json")!
    }

    override func processReceivedData(_ data: Data) -> Bool {
        do {
            levels = try JSONDecoder().decode([RisksUILevel].self, from: data)
            return true
        } catch {
            return false
        }
    }

    override func notifyObservers() {
        observers.forEach { $0.observer?.risksUIChanged() }
    }

}

extension RisksUIManager {
    
    func addObserver(_ observer: RisksUIChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(RisksUIObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: RisksUIChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: RisksUIChangesObserver) -> RisksUIObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
}

extension RisksUIManager: StatusChangesObserver {
 
    func statusRiskLevelDidChange() {
        notifyObservers()
    }
    
}
