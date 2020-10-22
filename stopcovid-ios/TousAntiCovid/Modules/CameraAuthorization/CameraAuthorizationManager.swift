// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CameraAuthorizationManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 18/05/2020 - for the TousAntiCovid project.
//


import UIKit
import AVFoundation

final class CameraAuthorizationManager {

    static func requestAuthorization(_ completion: @escaping (_ granted: Bool, _ isFirstTimeRequest: Bool) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true, false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted, true)
                }
            }
        case .denied, .restricted:
            completion(false, false)
        @unknown default:
            completion(false, false)
        }
    }
    
}
