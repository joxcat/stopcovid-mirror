// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationsManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import StorageSDK

protocol AttestationsChangesObserver: class {
    
    func attestationsDidUpdate()
    
}

final class AttestationsObserverWrapper: NSObject {
    
    weak var observer: AttestationsChangesObserver?
    
    init(observer: AttestationsChangesObserver) {
        self.observer = observer
    }
    
}

final class AttestationsManager: NSObject {
    
    static let shared: AttestationsManager = AttestationsManager()
    
    var formFields: [[AttestationFormField]] = []
    var formFieldsCount: Int { formFields.reduce([], +).count }
    var attestations: [Attestation] { storageManager.attestations().sorted { $0.timestamp < $1.timestamp } }
    
    private var observers: [AttestationsObserverWrapper] = []
    private var storageManager: StorageManager!
    
    @UserDefault(key: .lastInitialAttestationFormBuildNumber)
    private var lastInitialAttestationFormBuildNumber: String? = nil
    
    @UserDefault(key: .saveAttestationFieldsData)
    private var saveMyData: Bool = false
    
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
        writeInitialFileIfNeeded()
        loadLocalAttestationForm()
        addObserver()
    }
    
    func fetchAttestationForm(timeout: Double? = nil, completion: (() -> ())? = nil) {
        guard !RemoteFileConstant.useOnlyLocalStrings else {
            completion?()
            return
        }
        fetchAllFiles(timeout: timeout, completion: completion)
    }
    
    func clearAllData() {
        storageManager.deleteAttestationsData()
        storageManager.deleteAllAttestationFields()
        saveMyData = false
    }
    
    func clearExpiredAttestations(durationInHours: Double) {
        storageManager.deleteExpiredAttestationsData(durationInHours: durationInHours)
    }
    
    func generateQRCode(for values: [String: String]) -> String? {
        generateQRCodeAssociatedText(for: values, templateString: ParametersManager.shared.qrCodeFormattedString)
    }
    
    func generateQRCodeDisplayableString(for values: [String: String]) -> String? {
        generateQRCodeAssociatedText(for: values, templateString: ParametersManager.shared.qrCodeFormattedStringDisplayed)
    }
    
    func generateQRCodeFooter(for values: [String: String]) -> String? {
        generateQRCodeAssociatedText(for: values, templateString: ParametersManager.shared.qrCodeFooterString)
    }
    
    private func generateQRCodeAssociatedText(for values: [String: String], templateString: String) -> String? {
        var qrCodeString: String = templateString
        values.forEach { key, value in
            qrCodeString = qrCodeString.replacingOccurrences(of: "<\(key)>", with: value)
        }
        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: "<[a-zA-Z0-9\\-]+>")
            qrCodeString = regex.stringByReplacingMatches(in: qrCodeString, range: NSRange(qrCodeString.startIndex..., in: qrCodeString), withTemplate: "qrCode.infoNotAvailable".localized)
        } catch {}
        return qrCodeString
    }
    
    func saveAttestation(timestamp: Int, qrCode: Data, footer: String, qrCodeString: String) {
        let attestation: Attestation = Attestation(timestamp: timestamp, qrCode: qrCode, footer: footer, qrCodeString: qrCodeString)
        storageManager.saveAttestation(attestation)
    }
    
    func deleteAttestation(_ attestation: Attestation) {
        storageManager.deleteAttestation(attestation)
    }
    
    func saveAttestationFieldValueForKey(_ key: String, value: String?) {
        storageManager.saveAttestationFieldValueForKey(key, value: value)
    }
    
    func getAttestationFieldValues() -> [String: String] {
        return storageManager.getAttestationFieldValues()
    }
    
    func getAttestationFieldValueForKey(_ key: String) -> String? {
        return storageManager.getAttestationFieldValueForKey(key)
    }
    
    func deleteAllAttestationFields() {
        storageManager.deleteAllAttestationFields()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(attestionsStorageDidUpdate), name: .attestationDataDidChange, object: nil)
    }
    
    @objc private func appDidBecomeActive() {
        fetchAttestationForm()
        clearExpiredAttestations(durationInHours: ParametersManager.shared.qrCodeDeletionHours)
    }
    
    @objc private func attestionsStorageDidUpdate() {
        notifyObservers()
    }
    
}

// MARK: - All fetching methods -
extension AttestationsManager {
    
    private func fetchAllFiles(timeout: Double? = nil, completion: (() -> ())? = nil) {
        fetchAttestationsFormFile(timeout: timeout) {
            DispatchQueue.main.async {
                self.notifyObservers()
                completion?()
            }
        }
    }
    
    private func fetchAttestationsFormFile(timeout: Double? = nil, completion: @escaping () -> ()) {
        let configuration: URLSessionConfiguration = .default
        if let timeout = timeout {
            configuration.timeoutIntervalForRequest = timeout
            configuration.timeoutIntervalForResource = timeout
        }
        let session: URLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        let dataTask: URLSessionDataTask = session.dataTask(with: AttestationsConstant.jsonUrl) { data, response, error in
            guard let data = data else {
                completion()
                return
            }
            do {
                self.formFields = try JSONDecoder().decode([[AttestationFormField]].self, from: data)
                try data.write(to: self.localAttestationFormUrl())
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
    
}

// MARK: - Local files management -
extension AttestationsManager {
    
    private func localAttestationFormUrl() -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("form.json")
    }
    
    private func loadLocalAttestationForm() {
        let localUrl: URL = localAttestationFormUrl()
        guard FileManager.default.fileExists(atPath: localUrl.path) else { return }
        guard let data = try? Data(contentsOf: localUrl) else { return }
        formFields = (try? JSONDecoder().decode([[AttestationFormField]].self, from: data)) ?? []
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("Attestations")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
    private func initialFileUrl() -> URL {
        Bundle.main.url(forResource: "form", withExtension: "json")!
    }
    
    private func writeInitialFileIfNeeded() {
        let fileUrl: URL = initialFileUrl()
        let destinationFileUrl: URL = createWorkingDirectoryIfNeeded().appendingPathComponent(fileUrl.lastPathComponent)
        let currentBuildNumber: String = UIApplication.shared.buildNumber
        let isNewAppVersion: Bool = lastInitialAttestationFormBuildNumber != currentBuildNumber
        if !FileManager.default.fileExists(atPath: destinationFileUrl.path) || RemoteFileConstant.useOnlyLocalStrings || isNewAppVersion {
            try? FileManager.default.removeItem(at: destinationFileUrl)
            try? FileManager.default.copyItem(at: fileUrl, to: destinationFileUrl)
            lastInitialAttestationFormBuildNumber = currentBuildNumber
        }
    }
    
}

extension AttestationsManager {
    
    func addObserver(_ observer: AttestationsChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(AttestationsObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: AttestationsChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: AttestationsChangesObserver) -> AttestationsObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.attestationsDidUpdate() }
    }
    
}

extension AttestationsManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
     
}
