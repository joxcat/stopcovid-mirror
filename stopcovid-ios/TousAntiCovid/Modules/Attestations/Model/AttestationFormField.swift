// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  AttestationFormField.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit

struct AttestationFormField: Codable {
    
    enum FieldType: String, Codable {
        case text
        case number
        case date
        case dateTime = "datetime"
        case list
        
        var keyboardType: UIKeyboardType? {
            switch self {
            case .number:
                return .namePhonePad
            case .text:
                return .default
            default:
                return nil
            }
        }
        
        var capitalizationType: UITextAutocapitalizationType { .sentences }
        
    }
    
    enum FieldContentType: String, Codable {
        case firstName
        case lastName
        case addressCity
        case addressLine1
        case addressPostalCode
        
        var textContentType: UITextContentType {
            switch self {
            case .firstName:
                return .givenName
            case .lastName:
                return .familyName
            case .addressCity:
                return .addressCity
            case .addressLine1:
                return .streetAddressLine1
            case .addressPostalCode:
                return .postalCode
            }
        }
        
    }
    
    let key: String
    let type: FieldType
    let contentType: FieldContentType?
    let items: [AttestationFormFieldItem]?
    
    var name: String { "attestation.form.\(key).label".localized }
    var placeholder: String { "attestation.form.\(key).placeholder".localized }
    
}
