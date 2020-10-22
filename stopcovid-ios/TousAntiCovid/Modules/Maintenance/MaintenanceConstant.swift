// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MaintenanceConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 20/05/2020 - for the TousAntiCovid project.
//


import Foundation

enum MaintenanceConstant {

    static let baseUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/maintenance")!
    static let fileName: String = "info-maintenance-v2.json"
    static var fileUrl: URL { baseUrl.appendingPathComponent(fileName) }
    static let minDurationBetweenUpdatesInSeconds: Double = 5.0 * 60.0
    
}
