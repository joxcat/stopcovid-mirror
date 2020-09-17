// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBServer.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import Foundation

public protocol RBServer {

    var publicKey: Data { get }
    
    // MARK: - v1 -
    func status(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ result: Result<RBStatusResponse, Error>) -> ())
    func report(code: String, helloMessages: [RBLocalProximity], completion: @escaping (_ error: Error?) -> ())
    func register(token: String, publicKey: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ())
    func unregister(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ())
    func deleteExposureHistory(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ())
    
    // MARK: - v2 updates -
    func registerV2(captcha: String, captchaId: String, publicKey: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ())
    
    // MARK: - v3 updates -
    func statusV3(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ result: Result<RBStatusResponse, Error>) -> ())
    func registerV3(captcha: String, captchaId: String, publicKey: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ())
    func unregisterV3(epochId: Int, ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ())
}
