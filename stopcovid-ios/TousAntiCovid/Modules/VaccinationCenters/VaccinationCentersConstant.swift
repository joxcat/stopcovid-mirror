// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCentersConstant.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/01/2021 - for the TousAntiCovid project.
//

import Foundation

enum VaccinationCentersConstant {
    
    static let jsonBaseUrl: URL = URL(string: "https://app.stopcovid.gouv.fr/infos/dep/")!
    
    static let vaccinationCentersFileName: String = "centres-vaccination.json"
    static let vaccinationCentersLastUpdateFileName: String = "lastUpdate.json"
    static let postalCodesDetailsFileUrl: URL = Bundle.main.url(forResource: "zip-geoloc", withExtension: "json")!
}
