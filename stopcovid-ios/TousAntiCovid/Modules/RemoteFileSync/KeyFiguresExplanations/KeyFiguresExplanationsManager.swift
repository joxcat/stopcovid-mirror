// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  LinksManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol KeyFiguresExplanationsChangesObserver: class {
    
    func keyFiguresExplanationsChanged()
    
}

final class KeyFiguresExplanationsObserverWrapper: NSObject {
    
    weak var observer: KeyFiguresExplanationsChangesObserver?
    
    init(observer: KeyFiguresExplanationsChangesObserver) {
        self.observer = observer
    }
    
}

final class KeyFiguresExplanationsManager: RemoteFileSyncManager {

    static let shared: KeyFiguresExplanationsManager = KeyFiguresExplanationsManager()
    var keyFiguresExplanationsSection: [KeyFiguresExplanationsSection] = []
    
    @UserDefault(key: .lastInitialKeyFiguresExplanationsBuildNumber)
    private var lastInitialKeyFiguresExplanationsBuildNumber: String? = nil
    
    @UserDefault(key: .lastKeyFiguresExplanationsUpdateDate)
    private var lastUpdateDate: Date = .distantPast
    
    private var observers: [KeyFiguresExplanationsObserverWrapper] = []
    
    override func canUpdateData() -> Bool {
        let now: Date = Date()
        let lastFetchIsTooOld: Bool = now.timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= RemoteFileConstant.minDurationBetweenUpdatesInSeconds
        let languageChanged: Bool = lastLanguageCode != Locale.currentLanguageCode
        return lastFetchIsTooOld || languageChanged
    }
    
    override func saveUpdatedAt() {
        self.lastUpdateDate = Date()
    }
    
    override func lastBuildNumber() -> String? { lastInitialKeyFiguresExplanationsBuildNumber }
    override func saveLastBuildNumber(_ buildNumber: String) {
        lastInitialKeyFiguresExplanationsBuildNumber = buildNumber
    }
    
    override func workingDirectoryName() -> String { "KeyFiguresExplanations" }
    
    override func initialFileUrl(for languageCode: String) -> URL {
        Bundle.main.url(forResource: "morekeyfigures-\(languageCode)", withExtension: "json") ?? Bundle.main.url(forResource: "morekeyfigures-\(Constant.defaultLanguageCode)", withExtension: "json")!
    }
    
    override func localFileUrl(for languageCode: String) -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("morekeyfigures-\(languageCode).json")
    }

    override func remoteFileUrl(for languageCode: String) -> URL {
        URL(string: "\(KeyFiguresExplanationsConstant.baseUrl)/morekeyfigures-\(languageCode).json")!
    }

    override func processReceivedData(_ data: Data) -> Bool {
        do {
            keyFiguresExplanationsSection = try JSONDecoder().decode([KeyFiguresExplanationsSection].self, from: data)
            return true
        } catch {
            return false
        }
    }

    override func notifyObservers() {
        observers.forEach { $0.observer?.keyFiguresExplanationsChanged() }
    }

}

extension KeyFiguresExplanationsManager {
    
    func addObserver(_ observer: KeyFiguresExplanationsChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(KeyFiguresExplanationsObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: KeyFiguresExplanationsChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: KeyFiguresExplanationsChangesObserver) -> KeyFiguresExplanationsObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
}
