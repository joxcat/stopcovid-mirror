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

protocol RBServer {

    func status(ebid: String, time: String, mac: String, completion: @escaping (_ result: Result<RBStatusResponse, Error>) -> ())
    func report(token: String, helloMessages: [RBLocalProximity], completion: @escaping (_ error: Error?) -> ())
    func register(captcha: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ())
    func unregister(ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ())
    func deleteExposureHistory(ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ())
    
}
