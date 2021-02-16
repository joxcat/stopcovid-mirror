// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCentersManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/01/2021 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK
import CoreLocation

protocol VaccinationCenterChangesObserver: class {
    
    func vaccinationCentersDidUpdate()
    
}

final class VaccinationCenterObserverWrapper: NSObject {
    
    weak var observer: VaccinationCenterChangesObserver?
    
    init(observer: VaccinationCenterChangesObserver) {
        self.observer = observer
    }
    
}

final class VaccinationCenterManager: NSObject {
    
    static let shared: VaccinationCenterManager = VaccinationCenterManager()
    
    var vaccinationCentersToDisplay: [VaccinationCenter]? {
        guard let vaccinationCenters = vaccinationCenters else { return nil }
        guard let currentLocation = currentLocation else { return vaccinationCenters }
        let sortedCenters: [VaccinationCenter] = vaccinationCenters.filter { $0.location != nil }.sorted {
            $0.location!.distance(from: currentLocation) < $1.location!.distance(from: currentLocation)
        }
        let filteredCenters: [VaccinationCenter] = [VaccinationCenter](sortedCenters.prefix(ParametersManager.shared.vaccinationCentersCount))
        return filteredCenters
    }
    
    private var vaccinationCenters: [VaccinationCenter]?
    
    @OptionalUserDefault(key: .currentVaccinationReferenceDepartmentCode)
    private var currentDepartmentCode: String?
    @OptionalUserDefault(key: .currentVaccinationReferenceLatitude)
    private var currentVaccinationReferenceLatitude: Double?
    @OptionalUserDefault(key: .currentVaccinationReferenceLongitude)
    private var currentVaccinationReferenceLongitude: Double?
    
    private var currentLocation: CLLocation? {
        guard let latitude = currentVaccinationReferenceLatitude else { return nil }
        guard let longitude = currentVaccinationReferenceLongitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private var observers: [VaccinationCenterObserverWrapper] = []
    private lazy var postalCodesDetails: JSON = {
        guard let data = try? Data(contentsOf: VaccinationCentersConstant.postalCodesDetailsFileUrl) else { return [:] }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSON else { return [:] }
        return json
    }()
    
    func start() {
        initializeCurrentDepartmentIfNeeded()
        loadLocalVaccinationCenters()
        addObserver()
    }
    
    func clearAllData() {
        vaccinationCenters = []
        currentDepartmentCode = nil
        currentVaccinationReferenceLatitude = nil
        currentVaccinationReferenceLongitude = nil
    }
    
    func reloadFiles() {
        vaccinationCenters = nil
        notifyVaccinationCentersUpdate()
        fetchNeededFiles()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        KeyFiguresManager.shared.addObserver(self)
    }
    
    @objc private func appDidBecomeActive() {
        fetchNeededFiles()
    }
    
    private func initializeCurrentDepartmentIfNeeded() {
        guard currentDepartmentCode == nil else { return }
        guard let postalCode = KeyFiguresManager.shared.currentPostalCode else { return }
        postalCodeDidUpdate(postalCode)
    }
    
    private func fetchNeededFiles() {
        guard let departmentCode = currentDepartmentCode else {
            self.setVaccincationCentersEmptyFollowingAnUpdateError()
            return
        }
        fetchLastUpdate(departmentCode: departmentCode) { result in
            switch result {
            case let .success(lastUpdate):
                if self.areVaccinationCentersOutdated(departmentCode: departmentCode, latestSha1: lastUpdate.sha1) {
                    self.fetchVaccinationCentersFile(departmentCode: departmentCode) { error in
                        guard error == nil else {
                            self.setVaccincationCentersEmptyFollowingAnUpdateError()
                            return
                        }
                        if let data = try? JSONEncoder().encode(lastUpdate) {
                            try? data.write(to: self.localLastUpdateUrl(departmentCode: departmentCode))
                        }
                        self.notifyVaccinationCentersUpdate()
                    }
                } else {
                    self.setVaccincationCentersEmptyFollowingAnUpdateError()
                }
            case .failure:
                self.setVaccincationCentersEmptyFollowingAnUpdateError()
            }
        }
    }
    
    private func fetchVaccinationCentersFile(departmentCode: String, completion: @escaping (_ error: Error?) -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let url: URL = VaccinationCentersConstant.jsonBaseUrl.appendingPathComponent(departmentCode)
                                                             .appendingPathComponent(VaccinationCentersConstant.vaccinationCentersFileName)
        let dataTask: URLSessionDataTask = session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(NSError.localizedError(message: "Missing data", code: 400))
                }
                return
            }
            do {
                self.vaccinationCenters = try JSONDecoder().decode([VaccinationCenter].self, from: data)
                try data.write(to: self.localVaccinationCentersUrl(departmentCode: departmentCode))
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
        dataTask.resume()
    }
    
    private func fetchLastUpdate(departmentCode: String, completion: @escaping (_ result: Result<VaccinationCenterLastUpdate, Error>) -> ()) {
        let session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let url: URL = VaccinationCentersConstant.jsonBaseUrl.appendingPathComponent(departmentCode)
                                                             .appendingPathComponent(VaccinationCentersConstant.vaccinationCentersLastUpdateFileName)
        let dataTask: URLSessionDataTask = session.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError.localizedError(message: "Missing data", code: 400)))
                }
                return
            }
            do {
                let lastUpdate: VaccinationCenterLastUpdate = try JSONDecoder().decode(VaccinationCenterLastUpdate.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(lastUpdate))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        dataTask.resume()
    }
    
    private func areVaccinationCentersOutdated(departmentCode: String?, latestSha1: String) -> Bool {
        guard let departmentCode = departmentCode else { return true }
        return latestSha1 != lastUpdateSha1(departmentCode: departmentCode)
    }
    
    private func lastUpdateSha1(departmentCode: String) -> String? {
        let fileUrl: URL = localLastUpdateUrl(departmentCode: departmentCode)
        guard let data = try? Data(contentsOf: fileUrl) else { return nil }
        guard let lastUpdate = try? JSONDecoder().decode(VaccinationCenterLastUpdate.self, from: data) else { return nil }
        return lastUpdate.sha1
    }
    
    private func postalCodeDetail(postalCode: String) -> PostalCodeDetails? {
        guard let detailsJson = postalCodesDetails[postalCode] as? JSON else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: detailsJson, options: []) else { return nil }
        guard let details = try? JSONDecoder().decode(PostalCodeDetails.self, from: data) else { return nil }
        return details
    }
    
    private func setVaccincationCentersEmptyFollowingAnUpdateError() {
        guard vaccinationCenters == nil else { return }
        vaccinationCenters = []
        notifyVaccinationCentersUpdate()
    }
    
}

// MARK: - Local files management -
extension VaccinationCenterManager {
    
    private func localVaccinationCentersUrl(departmentCode: String) -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("\(departmentCode)-centers.json")
    }
    
    private func localLastUpdateUrl(departmentCode: String) -> URL {
        let directoryUrl: URL = self.createWorkingDirectoryIfNeeded()
        return directoryUrl.appendingPathComponent("\(departmentCode)-lastUpdate.json")
    }
    
    private func loadLocalVaccinationCenters() {
        guard let departmentCode = currentDepartmentCode else {
            vaccinationCenters = []
            return
        }
        let localUrl: URL = localVaccinationCentersUrl(departmentCode: departmentCode)
        guard FileManager.default.fileExists(atPath: localUrl.path) else {
            vaccinationCenters = []
            return
        }
        guard let data = try? Data(contentsOf: localUrl) else {
            vaccinationCenters = []
            return
        }
        vaccinationCenters = (try? JSONDecoder().decode([VaccinationCenter].self, from: data)) ?? []
    }
    
    private func createWorkingDirectoryIfNeeded() -> URL {
        let directoryUrl: URL = FileManager.libraryDirectory().appendingPathComponent("VaccinationCenters")
        if !FileManager.default.fileExists(atPath: directoryUrl.path, isDirectory: nil) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false, attributes: nil)
        }
        return directoryUrl
    }
    
}

extension VaccinationCenterManager {
    
    func addObserver(_ observer: VaccinationCenterChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(VaccinationCenterObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: VaccinationCenterChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: VaccinationCenterChangesObserver) -> VaccinationCenterObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyVaccinationCentersUpdate() {
        observers.forEach { $0.observer?.vaccinationCentersDidUpdate() }
    }
    
}

extension VaccinationCenterManager: KeyFiguresChangesObserver {
    
    func keyFiguresDidUpdate() {}
    
    func postalCodeDidUpdate(_ postalCode: String?) {
        guard let postalCode = postalCode else {
            clearAllData()
            notifyVaccinationCentersUpdate()
            return
        }
        var foundDetails: PostalCodeDetails? = postalCodeDetail(postalCode: postalCode)
        if let postalCodeInt = Int(postalCode), foundDetails == nil {
            let sameDepartmentPostalCodes: [Int] = [String](postalCodesDetails.keys).filter { $0.prefix(2) == postalCode.prefix(2) }.compactMap { Int($0) }
            let sortedPostalCodes: [Int] = sameDepartmentPostalCodes.sorted {
                abs($0 - postalCodeInt) < abs($1 - postalCodeInt)
            }
            if let nearestPostalCode = sortedPostalCodes.first {
                foundDetails = postalCodeDetail(postalCode: "\(nearestPostalCode)")
            }
        }
        currentVaccinationReferenceLatitude = foundDetails?.latitude
        currentVaccinationReferenceLongitude = foundDetails?.longitude
        guard foundDetails?.department != currentDepartmentCode || vaccinationCenters?.isEmpty != false else {
            notifyVaccinationCentersUpdate()
            return
        }
        currentDepartmentCode = foundDetails?.department
        loadLocalVaccinationCenters()
        if vaccinationCenters?.isEmpty == true {
            vaccinationCenters = nil
        }
        notifyVaccinationCentersUpdate()
        fetchNeededFiles()
    }
    
}

extension VaccinationCenterManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: Constant.Server.resourcesCertificate) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
     
}
