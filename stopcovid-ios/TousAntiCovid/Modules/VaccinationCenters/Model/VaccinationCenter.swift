// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationCenter.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/01/2021 - for the TousAntiCovid project.
//

import Foundation
import CoreLocation

struct VaccinationCenter: Decodable {

    let name: String
    let streetNumber: String
    let streetName: String
    let postalCode: String
    let locality: String
    let latitude: Double?
    let longitude: Double?
    let url: String?
    let tel: String?
    let modalities: String?
    let planning: String?
    private let openingTimestamp: Double?

    var availabilityTimestamp: Double? {
        guard let openingTimestamp = openingTimestamp else { return nil }
        guard let endOfDayTimestamp = Date().roundingToEndOfDay()?.timeIntervalSince1970 else { return openingTimestamp }
        return openingTimestamp > endOfDayTimestamp ? openingTimestamp : nil
    }

    var location: CLLocation? {
        guard let latitude = latitude else { return nil }
        guard let longitude = longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "nom"
        case streetNumber = "adresseNum"
        case streetName = "adresseVoie"
        case postalCode = "communeCP"
        case locality = "communeNom"
        case latitude
        case longitude
        case openingTimestamp = "dateOuverture"
        case url = "rdvURL"
        case tel = "rdvTel"
        case modalities = "rdvModalites"
        case planning = "rdvPlanning"
    }

}
