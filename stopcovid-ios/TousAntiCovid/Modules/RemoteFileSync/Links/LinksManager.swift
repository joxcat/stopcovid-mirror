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

protocol LinksChangesObserver: class {
    
    func linksChanged()
    
}

final class LinksObserverWrapper: NSObject {
    
    weak var observer: LinksChangesObserver?
    
    init(observer: LinksChangesObserver) {
        self.observer = observer
    }
    
}

final class LinksManager: RemoteFileSyncManager {

    static let shared: LinksManager = LinksManager()
    var linksSections: [LinksSection] = []
    
    @UserDefault(key: .lastInitialLinksBuildNumber)
    private var lastInitialLinksBuildNumber: String? = nil
    
    @UserDefault(key: .lastLinksUpdateDate)
    private var lastUpdateDate: Date = .distantPast
    
    private var observers: [LinksObserverWrapper] = []
    
    override func canUpdateData() -> Bool {
        let now: Date = Date()
        let lastFetchIsTooOld: Bool = now.timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 >= RemoteFileConstant.minDurationBetweenUpdatesInSeconds
        let languageChanged: Bool = lastLanguageCode != Locale.currentLanguageCode
        return lastFetchIsTooOld || languageChanged
    }
    
    override func saveUpdatedAt() {
        self.lastUpdateDate = Date()
    }
    
    override func lastBuildNumber() -> String? { lastInitialLinksBuildNumber }
    override func saveLastBuildNumber(_ buildNumber: String) {
        lastInitialLinksBuildNumber = buildNumber
    }
    
    override func workingDirectoryName() -> String { "Links" }
    
    override func initialFileUrl(for languageCode: String) -> URL {
        Bundle.main.url(forResource: "links-\(languageCode)", withExtension: "json") ?? Bundle.main.url(forResource: "links-\(Constant.defaultLanguageCode)", withExtension: "json")!
    }
    
    override func localFileUrl(for languageCode: String) -> URL {
        createWorkingDirectoryIfNeeded().appendingPathComponent("links-\(languageCode).json")
    }
    
    override func remoteFileUrl(for languageCode: String) -> URL {
        URL(string: "\(LinksConstant.baseUrl)/links-\(languageCode).json")!
    }

    override func processReceivedData(_ data: Data) -> Bool {
        do {
            linksSections = try JSONDecoder().decode([LinksSection].self, from: data)
            return true
        } catch {
            return false
        }
    }

    override func notifyObservers() {
        observers.forEach { $0.observer?.linksChanged() }
    }

}

extension LinksManager {
    
    func addObserver(_ observer: LinksChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(LinksObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: LinksChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: LinksChangesObserver) -> LinksObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
}
