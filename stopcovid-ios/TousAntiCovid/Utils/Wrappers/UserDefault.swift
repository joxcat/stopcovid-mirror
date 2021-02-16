// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UserDefault.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2019.
//

import UIKit

@propertyWrapper
final class UserDefault<T> {
    
    private var defaults: UserDefaults = .standard
    let key: Key
    let defaultValue: T
    
    var projectedValue: String { key.rawValue }
    
    var wrappedValue: T {
        get { defaults.object(forKey: key.rawValue) as? T ?? defaultValue }
        set {
            defaults.set(newValue, forKey: key.rawValue)
            defaults.synchronize()
        }
    }

    init(wrappedValue: T, key: Key, userDefault: UserDefaults = .standard) {
        self.defaultValue = wrappedValue
        self.key = key
        self.defaults = userDefault
    }
    
}

extension UserDefault {
    
    enum Key: String {
        case isAppAlreadyInstalled = "isAppAlreadyInstalled_v2"
        case isOnboardingDone = "isOnboardingDone_v2"
        case currentPostalCode
        case currentDepartmentName
        case lastStringsUpdateDate
        case lastPrivacyUpdateDate
        case lastLinksUpdateDate
        case lastKeyFiguresExplanationsUpdateDate
        case lastRemoteFileLanguageCode
        case lastInitialStringsBuildNumber
        case lastInitialPrivacyBuildNumber
        case lastInitialLinksBuildNumber
        case lastInitialKeyFiguresExplanationsBuildNumber
        case lastMaintenanceUpdateDate
        case infoCenterLastUpdatedAt
        case infoCenterDidReceiveNewInfo
        case lastInfoLanguageCode
        case keyFiguresLastUpdatedAt
        case lastInitialAttestationFormBuildNumber
        case saveAttestationFieldsData
        case didAlreadySeeVenuesRecordingOnboarding
        case venuesFeaturedWasActivatedAtLeastOneTime
        case privateEventQrCodeString
        case privateEventQrCodeData
        case privateEventQrCodeDate
        case currentVaccinationReferenceDepartmentCode
        case currentVaccinationReferenceLatitude
        case currentVaccinationReferenceLongitude
        
        case lastNotificationTimestamp
        case showNewInfoNotification
    }
    
}
