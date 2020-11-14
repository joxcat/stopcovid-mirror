// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  KeyFigure.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/10/2020 - for the TousAntiCovid project.
//

import UIKit

struct KeyFigure: Codable {
    
    enum Category: String, Codable {
        case health
        case app
    }
    
    enum Trend: Int, Codable {
        
        case decrease = -1
        case same = 0
        case increase = 1
        
        var image: UIImage {
            switch self {
            case .decrease:
                return Asset.Images.trendDown.image
            case .same:
                return Asset.Images.trendSteady.image
            case .increase:
                return Asset.Images.trendUp.image
            }
        }
        
        var accessibilityLabel: String {
            switch self {
            case .decrease:
                return "accessibility.hint.keyFigure.valueDown".localized
            case .same:
                return "accessibility.hint.keyFigure.valueSteady".localized
            case .increase:
                return "accessibility.hint.keyFigure.valueUp".localized
            }
        }
        
    }
    
    let labelKey: String
    let category: Category
    let valueGlobalToDisplay: String
    let valueGlobal: Double?
    let isFeatured: Bool
    let lastUpdate: Int
    let trend: Trend?
    let valuesDepartments: [KeyFigureDepartment]?
    
    var label: String { "\(labelKey).label".localized.trimmingCharacters(in: .whitespaces) }
    var shortLabel: String { "\(labelKey).shortLabel".localized.trimmingCharacters(in: .whitespaces) }
    var description: String { "\(labelKey).description".localized.trimmingCharacters(in: .whitespaces) }
    var color: UIColor {
        let colorCode: String = UIColor.isDarkMode ? "\(labelKey).colorCode.dark".localized : "\(labelKey).colorCode.light".localized
        return UIColor(hexString: colorCode)
    }
    var currentTrend: Trend { trend ?? .same }
    
    var formattedDate: String {
        switch category {
        case .health:
            return Date(timeIntervalSince1970: Double(lastUpdate)).relativelyFormattedDay(prefixStringKey: "keyFigures.update")
        case .app:
            return Date(timeIntervalSince1970: Double(lastUpdate)).relativelyFormatted(prefixStringKey: "keyFigures.update")
        }
    }
    
    var currentDepartmentSpecificKeyFigure: KeyFigureDepartment? {
        guard KeyFiguresManager.shared.displayDepartmentLevel else { return nil }
        return departmentSpecificKeyFigureForPostalCode(KeyFiguresManager.shared.currentPostalCode)
    }
    
    func departmentSpecificKeyFigureForPostalCode(_ postalCode: String?) -> KeyFigureDepartment? {
        guard KeyFiguresManager.shared.displayDepartmentLevel else { return nil }
        guard let postalCode = postalCode else { return nil }
        var departmentNumber: String = "\(postalCode.prefix(2))"
        if departmentNumber == "20" {
            departmentNumber = ["200", "201"].contains(postalCode.prefix(3)) ? "2A" : "2B"
        } else if ["97", "98"].contains(postalCode.prefix(2)) {
            departmentNumber = "\(postalCode.prefix(3))"
        }
        return valuesDepartments?.first { $0.number == departmentNumber }
    }
    
}
