// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Date+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 04/05/2020 - for the TousAntiCovid project.
//

import Foundation

extension Date {
    
    func timeFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func shortDateFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self).uppercased()
    }
    
    func shortTimeFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self).uppercased()
    }
    
    func dayMonthFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        return formatter.string(from: self)
    }
    
    func dayShortMonthFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter.string(from: self)
    }

    func dayShortMonthYearFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMyyyy")
        return formatter.string(from: self)
    }

    func fullDayMonthFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: self)
    }
    
    func dayMonthYearFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter.string(from: self)
    }
    
    func fullTextFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    func fullDateTimeFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }

    func dateByAddingDays(_ days: Int) -> Date {
        addingTimeInterval(Double(days) * 24.0 * 3600.0)
    }
    
    func dateByAddingYears(_ years: Int) -> Date {
        var dateComponent: DateComponents = DateComponents()
        dateComponent.year = years
        return Calendar.current.date(byAdding: dateComponent, to: self)!
    }

    func fullDateFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }

    func testCodeFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "dMMMyyyy"
        return formatter.string(from: self).uppercased()
    }

    func underscoreDateFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy"
        return formatter.string(from: self).uppercased()
    }
    
    #if !WIDGET
    func relativelyFormatted(prefixStringKey: String = "myHealthController.notification.update", displayYear: Bool = false) -> String {
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized), %@", timeFormatted())
            return prefixStringKey.isEmpty ? lastPart : String(format: prefixStringKey.localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized), %@", timeFormatted())
            return prefixStringKey.isEmpty ? lastPart : String(format: prefixStringKey.localized, lastPart)
        } else {
            return prefixStringKey.isEmpty ? String(format: "%@, %@", displayYear ? dayMonthYearFormatted() : dayMonthFormatted(), timeFormatted()) : String(format: "\(prefixStringKey.localized), %@", dayMonthFormatted(), timeFormatted())
        }
    }
    
    func relativelyFormattedDay(prefixStringKey: String = "myHealthController.notification.update") -> String {
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized)")
            return String(format: prefixStringKey.localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized)")
            return String(format: prefixStringKey.localized, lastPart)
        } else {
            return String(format: "\(prefixStringKey.localized)", dayMonthFormatted())
        }
    }
    
    func accessibilityRelativelyFormattedDate(prefixStringKey: String = "myHealthController.notification.update") -> String {
        let hourComponents: DateComponents = Calendar.current.dateComponents([.hour, .minute], from: self)
        let accessibilityHour: String = DateComponentsFormatter.localizedString(from: hourComponents, unitsStyle: .spellOut) ?? ""
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized), %@", accessibilityHour)
            return String(format: prefixStringKey.localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized), %@", accessibilityHour)
            return String(format: prefixStringKey.localized, lastPart)
        } else {
            let accessibilityDate: String = DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .none)
            return String(format: "\(prefixStringKey.localized), %@", accessibilityDate, accessibilityHour)
        }
    }
    
    
    func relativelyFormattedForWidget() -> String {
        String(format: "\("myHealthController.notification.update".localized), %@", dayMonthFormatted(), timeFormatted())
    }
    
    func agoFormatted() -> String {
        let elapsedTime: Int = Int(Date().timeIntervalSince1970 - timeIntervalSince1970)
        let secondsInADay: Int = 24 * 3600
        switch elapsedTime {
        case 0..<60:
            return "common.justNow".localized
        case 60..<3600:
            // Minutes count.
            return String(format: "common.ago".localized, "")
        case 3600..<secondsInADay:
            // Hours count.
            return String(format: "common.ago".localized, "")
        case secondsInADay..<(7 * secondsInADay):
            // Days count.
            return String(format: "common.ago".localized, "")
        default:
            // Date + hours
            return ""
        }
    }
    #endif
    
    func roundingToBeginningOfDay() -> Date? {
        var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)
    }
    
    func roundingToEndOfDay() -> Date? {
        var components: DateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)
    }

}

extension Date {
    
    var timeIntervalSince1900: Int {
        return Int(timeIntervalSince1970) + 2208988800
    }
    
    init(timeIntervalSince1900: Int) {
        self.init(timeIntervalSince1970: Double(timeIntervalSince1900 - 2208988800))
    }
    
    func roundedTimeIntervalSince1900(interval: Int) -> Int {
        let timeInterval: Int = timeIntervalSince1900
        return timeInterval + interval / 2 - (timeInterval + interval / 2) % interval
    }
    
}
