// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Certificates.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/05/2020 - for the TousAntiCovid project.
//


import Foundation

public final class CertificatePinning {

    public static func validateChallenge(_ challenge: URLAuthenticationChallenge, certificateFile: Data, completion: @escaping (_ validated: Bool, _ credential: URLCredential?) -> ()) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completion(false, nil)
            return
        }
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completion(false, nil)
            return
        }
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completion(false, nil)
            return
        }
        
        let serverCertificateData: CFData = SecCertificateCopyData(serverCertificate)
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(serverCertificateData)
        let size: CFIndex = CFDataGetLength(serverCertificateData)
        let cert1Base64: String = Data(bytes: data, count: size).base64EncodedString()
        
        guard let cert2Base64 = self.fileBase64Content(certificateFile) else {
            completion(false, nil)
            return
        }
        let certificateIsValid: Bool = cert1Base64 == cert2Base64
        
        completion(certificateIsValid, URLCredential(trust: serverTrust))
    }
    
    private static func fileBase64Content(_ certificateFile: Data) -> String? {
        return String(data: certificateFile, encoding: .utf8)?.svCleaningPEMStrings()
    }

}
