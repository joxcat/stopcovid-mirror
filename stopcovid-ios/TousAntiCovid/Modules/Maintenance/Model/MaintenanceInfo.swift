// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MaintenanceInfo.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/05/2020 - for the TousAntiCovid project.
//


import UIKit

struct MaintenanceInfo: Decodable {

    enum Mode: String, Decodable {
        case upgrade
        case maintenance
    }
    
    let isActive: Bool?
    let mode: Mode?
    let minRequiredBuildNumber: Int?
    private let message: [String: String]?
    private let buttonTitle: [String: String]?
    private let buttonURL: [String: String]?
    
    var localizedMessage: String? { localizedValue(from: message) }
    var localizedButtonTitle: String? { localizedValue(from: buttonTitle) }
    var localizedButtonUrl: String? { localizedValue(from: buttonURL) }
    
    private func localizedValue(from: [String: String]?) -> String? {
        guard let from = from else { return nil }
        if let description = from[Locale.currentLanguageCode], !description.isEmpty {
            return description
        }
        return from[Constant.defaultLanguageCode]
    }
    
    func shouldShow() -> Bool {
        let currentBuildNumber: Int = Int(UIApplication.shared.buildNumber) ?? 0
        return  (isActive ?? false) && (minRequiredBuildNumber ?? 0 > currentBuildNumber)
    }
    
}
