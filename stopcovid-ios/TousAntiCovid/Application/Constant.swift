// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Constant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit
import ServerSDK

enum Constant {
    
    static let defaultLanguageCode: String = "en"
    static let maxPushDatesCount: Int = 100
    static let secondsBeforeStatusRetry: Double = 60.0
    
    #if targetEnvironment(simulator)
    static let isSimulator: Bool = true
    #else
    static let isSimulator: Bool = false
    #endif
    
    #if DEBUG
    static let isDebug: Bool = true
    #else
    static let isDebug: Bool = false
    #endif
    
    enum Server {
        
        static var baseUrl: URL { URL(string: "https://api.stopcovid.gouv.fr/api/\(ParametersManager.shared.apiVersion.rawValue)")! }

        static let publicKey: Data = Data(base64Encoded: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEAc9IDt6qJq453SwyWPB94JaLB2VfTAcL43YVtMr3HhDCd22gKaQXIbX1d+tNhfvaKM51sxeaXziPjntUzbTNiw==")!
        
        static var certificate: Data { Bundle.main.fileDataFor(fileName: "api.stopcovid.gouv.fr", ofType: "pem") ?? Data() }

        static var resourcesCertificate: Data { Bundle.main.fileDataFor(fileName: "app.stopcovid.gouv.fr", ofType: "pem") ?? Data() }

        static let jsonVersion: Int = 25

        static let baseJsonUrl: String = "https://app.stopcovid.gouv.fr/json/version-\(jsonVersion)"
        static let configUrl: URL = URL(string: "\(baseJsonUrl)/config.json")!

    }
}

typealias JSON = [String: Any]
