// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VenueQrCode+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 25/11/2020 - for the TousAntiCovid project.
//

import Foundation
import StorageSDK
import ServerSDK

extension VenueQrCode {
    
    enum QrCodeType: Int {
        case `static` = 0
        case dynamic = 1
        
        var name: String {
            switch self {
            case .static:
                return "STATIC"
            case .dynamic:
                return "DYNAMIC"
            }
        }
    }
    
    var venueTypeDisplayName: String {
        var type: String = "venueType.\(venueType.lowercased())".localizedOrEmpty
        type = type.isEmpty ? "venueType.default".localized : type
        
        let date: Date = Date(timeIntervalSince1900: ntpTimestamp)
        let dateString: String = date.relativelyFormatted(prefixStringKey: "", displayYear: true)
        
        return String(format: "venuesHistoryController.entry".localized, type, dateString)
    }
    
    func toWarningServerVisit() -> WarningServerVisit {
        let qrCode: WarningServerVisitQrCode = WarningServerVisitQrCode(type: QrCodeType(rawValue: qrType)?.name ?? "",
                                                                        venueType: venueType,
                                                                        venueCategory: venueCategory,
                                                                        venueCapacity: venueCapacity,
                                                                        uuid: uuid)
        return WarningServerVisit(timestamp: "\(ntpTimestamp)",
                                  qrCode: qrCode)
    }
    
}
