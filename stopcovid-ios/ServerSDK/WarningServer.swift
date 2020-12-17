// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  WarningServer.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation

public final class WarningServer: NSObject {
    
    public static let shared: WarningServer = WarningServer()
    
    private var baseUrl: (() -> URL?)!
    private var certificateFile: Data!
    
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "fr.gouv.stopcovid.ios.ServerSDK-Warning")
        backgroundConfiguration.timeoutIntervalForRequest = ServerConstant.timeout
        backgroundConfiguration.timeoutIntervalForResource = ServerConstant.timeout
        backgroundConfiguration.waitsForConnectivity = true
        backgroundConfiguration.sessionSendsLaunchEvents = true
        backgroundConfiguration.shouldUseExtendedBackgroundIdleMode = true
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    private var receivedData: [String: Data] = [:]
    private var completions: [String: Server.ProcessRequestCompletion] = [:]
    
    public func start(baseUrl: @escaping () -> URL?, certificateFile: Data) {
        self.baseUrl = baseUrl
        self.certificateFile = certificateFile
    }
    
    public func wstatus(staticQrCodePayloads: [(payload: String, timestamp: Int)], dynamicQrCodePayloads: [(payload: String, timestamp: Int)], completion: @escaping (_ result: Result<Bool, Error>) -> ()) {
        guard let baseUrl = self.baseUrl() else {
            completion(.success(false))
            return
        }
        let staticTokens: [RBWarningServerVisitToken] = staticQrCodePayloads.map { RBWarningServerVisitToken(type: "STATIC", payload: $0.payload, timestamp: "\($0.timestamp)") }
        let dynamicTokens: [RBWarningServerVisitToken] = dynamicQrCodePayloads.map { RBWarningServerVisitToken(type: "DYNAMIC", payload: $0.payload, timestamp: "\($0.timestamp)") }
        let body: RBWarningServerStatusBody = RBWarningServerStatusBody(visitTokens: staticTokens + dynamicTokens)
        self.processRequest(url: baseUrl.appendingPathComponent("wstatus"), method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBWarningServerStatusResponse = try JSONDecoder().decode(RBWarningServerStatusResponse.self, from: data)
                    completion(.success(response.atRisk))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public func wreport(token: String, visits: [WarningServerVisit], completion: @escaping (_ error: Error?) -> ()) {
        guard let baseUrl = self.baseUrl() else {
            completion(nil)
            return
        }
        let visits: [RBWarningServerVisit] = visits.map { RBWarningServerVisit.from(visit: $0) }
        let body: RBWarningServerReportBody = RBWarningServerReportBody(visits: visits)
        self.processRequest(url: baseUrl.appendingPathComponent("wreport"), method: .post, token: token, body: body) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

}

extension WarningServer {
    
    private func processRequest(url: URL, method: Server.Method, token: String? = nil, body: RBServerBody, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        do {
            let bodyData: Data = try body.toData()
            let requestId: String = url.lastPathComponent
            guard completions[requestId] == nil else {
                completion(.failure(NSError.svLocalizedError(message: "A request for \"\(requestId)\" is already being treated", code: 0)))
                return
            }
            completions[requestId] = completion
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = method.rawValue
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
            request.httpBody = bodyData
            let task: URLSessionDownloadTask = session.downloadTask(with: request)
            task.taskDescription = requestId
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
}

extension WarningServer: URLSessionDelegate, URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                if task.response?.svIsError == true {
                    let statusCode: Int = task.response?.svStatusCode ?? 0
                    let message: String = receivedData.isEmpty ? "No data received from the server" : (String(data: receivedData, encoding: .utf8) ?? "Unknown error")
                    completion(.failure(NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message))", code: statusCode)))
                } else {
                    completion(.success(receivedData))
                }
            }
            self.completions[requestId] = nil
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let requestId: String = downloadTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        guard let data = try? Data(contentsOf: location) else { return }
        try? FileManager.default.removeItem(at: location)
        DispatchQueue.main.async {
            if downloadTask.response?.svIsError == true {
                let statusCode: Int = downloadTask.response?.svStatusCode ?? 0
                let message: String? = data.isEmpty ? "No logs received from the server" : String(data: data, encoding: .utf8)
                completion(.failure(NSError.svLocalizedError(message: "Uknown error (\(statusCode)). (\(message ?? "N/A"))", code: statusCode)))
                self.completions[requestId] = nil
            } else {
                self.receivedData[requestId] = data
            }
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        CertificatePinning.validateChallenge(challenge, certificateFile: certificateFile) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
