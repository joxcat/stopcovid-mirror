// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  InfoCenterManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

protocol InfoCenterChangesObserver: class {
    
    func infoCenterDidUpdate()
    
}

final class InfoCenterObserverWrapper: NSObject {
    
    weak var observer: InfoCenterChangesObserver?
    
    init(observer: InfoCenterChangesObserver) {
        self.observer = observer
    }
    
}

final class InfoCenterManager: NSObject {
    
    static let shared: InfoCenterManager = InfoCenterManager()
    
    var info: [Info] { rawInfo.filter { !$0.title.isEmpty && !$0.description.isEmpty } }
    var labels: [String: String] = [:]
    
    @UserDefault(key: .infoCenterLastUpdatedAt)
    var lastUpdatedAt: Int = 0
    @UserDefault(key: .infoCenterDidReceiveNewInfo)
    var didReceiveNewInfo: Bool = false {
        didSet { notifyObservers() }
    }
    
    private var rawInfo: [Info] = []
    private var tags: [InfoTag] = []
    
    @UserDefault(key: .isOnboardingDone)
    private var isOnboardingDone: Bool = false
    
    @UserDefault(key: .lastInfoLanguageCode)
    private var lastInfoLanguageCode: String? = nil
    
    private var observers: [InfoCenterObserverWrapper] = []
    
    func start() {
        loadLocalTags()
        loadLocalInfoCenter()
        loadLocalLabels()
        addObserver()
    }
    
    func tagsForIds(_ ids: [String]) -> [InfoTag] {
        tags.filter { ids.contains($0.id) }
    }
    
    func fetchInfo(force: Bool = false) {
        if force {
            lastUpdatedAt = 0
            fetchAllFiles(force: true)
        } else {
            fetchAllFiles()
        }
    }
    
    func refetchContent() {
        lastUpdatedAt = 0
        fetchAllFiles()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        fetchAllFiles()
    }
    
}

// MARK: - All fetching methods -
extension InfoCenterManager {
    
    private func labelsUrl(for languageCode: String) -> URL {
        URL(string: "\(InfoCenterConstant.baseUrl)/info-labels-\(languageCode).json")!
    }
    
    private func fetchAllFiles(force: Bool = false) {
        let isInitialFetch: Bool = lastUpdatedAt == 0
        fetchLastUpdatedAtFile { areUpdatesAvailable, languageChanged, lastUpdatedAt, informAboutNews in
            guard areUpdatesAvailable || languageChanged else { return }
            self.fetchTagsFile {
                self.fetchInfoCenterFile {
                    self.fetchLabelsFile(languageCode: Locale.currentLanguageCode) {
                        self.lastUpdatedAt = lastUpdatedAt
                        guard !force && informAboutNews else { return }
                        DispatchQueue.main.async {
                            self.didReceiveNewInfo = true
                            if self.isOnboardingDone && areUpdatesAvailable && !isInitialFetch {
                                NotificationsManager.shared.triggerInfoCenterNewsAvailableNotification()
                                if UIApplication.shared.applicationState != .active {
                                    UIApplication.shared.applicationIconBadgeNumber = 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchLastUpdatedAtFile(_ completion: @escaping (_ areUpdatesAvailable: Bool, _ languageChanged: Bool, _ lastUpdatedAt: Int, _ informAboutNews: Bool) -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let dataTask: URLSessionDataTask = session.dataTask(with: InfoCenterConstant.lastUpdatedAtUrl) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(false, false, 0, false)
                }
                return
            }
            do {
                let lastUpdatedAtJson: InfoLastUpdatedAt = try JSONDecoder().decode(InfoLastUpdatedAt.self, from: data)
                let areJsonUpdatesAvailable: Bool = self.lastUpdatedAt < lastUpdatedAtJson.lastUpdatedAt
                let lastUpdateWasMoreThan5MinsAgo: Bool = Date().timeIntervalSince1970 - Double(self.lastUpdatedAt) > 5.0 * 60.0
                let areUpdatesAvailable: Bool = areJsonUpdatesAvailable || lastUpdateWasMoreThan5MinsAgo
                let languageChanged: Bool = self.lastInfoLanguageCode != Locale.currentLanguageCode
                DispatchQueue.main.async {
                    completion(areUpdatesAvailable, languageChanged, lastUpdatedAtJson.lastUpdatedAt, areJsonUpdatesAvailable)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, false, 0, false)
                }
            }
        }
        dataTask.resume()
    }
    
    private func fetchTagsFile(_ completion: @escaping () -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let dataTask: URLSessionDataTask = session.dataTask(with: InfoCenterConstant.tagsUrl) { data, response, error in
            guard let data = data else {
                completion()
                return
            }
            do {
                self.tags = try JSONDecoder().decode([InfoTag].self, from: data)
                try data.write(to: self.localTagsUrl())
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
        dataTask.resume()
    }
    
    private func fetchInfoCenterFile(_ completion: @escaping () -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let dataTask: URLSessionDataTask = session.dataTask(with: InfoCenterConstant.infoCenterUrl) { data, response, error in
            guard let data = data else {
                completion()
                return
            }
            do {
                self.rawInfo = try JSONDecoder().decode([Info].self, from: data)
                try data.write(to: self.localInfoCenterUrl())
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
        dataTask.resume()
    }
    
    private func fetchLabelsFile(languageCode: String, completion: @escaping () -> ()) {
        let url: URL = labelsUrl(for: languageCode)
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let dataTask: URLSessionDataTask = session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion()
                return
            }
            do {
                let localUrl: URL = self.localLabelsUrl(for: languageCode)
                guard let labelsDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { return }
                self.labels = labelsDict
                try data.write(to: localUrl)
                self.lastInfoLanguageCode = Locale.currentLanguageCode
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                if languageCode != Constant.defaultLanguageCode {
                    self.fetchLabelsFile(languageCode: Constant.defaultLanguageCode, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
        dataTask.resume()
    }
    
}

// MARK: - Local files management -
extension InfoCenterManager {
    
    private func localTagsUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("info-tags.json")
    }
    
    private func localInfoCenterUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("info-center.json")
    }
    
    private func localLabelsUrl(for languageCode: String) -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("info-labels-\(languageCode).json")
    }
    
    private func loadLocalTags() {
        let localUrl: URL = localTagsUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        tags = (try? JSONDecoder().decode([InfoTag].self, from: data)) ?? []
    }
    
    private func loadLocalInfoCenter() {
        let localUrl: URL = localInfoCenterUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        rawInfo = (try? JSONDecoder().decode([Info].self, from: data)) ?? []
    }
    
    private func loadLocalLabels() {
        var localUrl: URL = localLabelsUrl(for: Locale.currentLanguageCode)
        if !FileManager.default.fileExists(atPath: localUrl.path) {
            localUrl = localLabelsUrl(for: Constant.defaultLanguageCode)
        }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        guard let labelsDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else { return }
        labels = labelsDict
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("InfoCenter")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
}

extension InfoCenterManager {
    
    func addObserver(_ observer: InfoCenterChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(InfoCenterObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: InfoCenterChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: InfoCenterChangesObserver) -> InfoCenterObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.infoCenterDidUpdate() }
    }
    
}


extension InfoCenterManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
     
}

extension String {
    
    var infoCenterLocalized: String { InfoCenterManager.shared.labels[self] ?? "" }
    
}
