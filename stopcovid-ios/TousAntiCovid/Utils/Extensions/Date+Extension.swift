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
    
    func dayMonthFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        return formatter.string(from: self)
    }
    
    func fullDayMonthFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: self)
    }
    
    func dayMonthYearFormatted() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "d MMMM YYYY"
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
    func relativelyFormatted() -> String {
        if Calendar.current.isDateInToday(self) {
            let lastPart: String = String(format: "\("common.today".localized), %@", timeFormatted())
            return String(format: "myHealthController.notification.update".localized, lastPart)
        } else if Calendar.current.isDateInYesterday(self) {
            let lastPart: String = String(format: "\("common.yesterday".localized), %@", timeFormatted())
            return String(format: "myHealthController.notification.update".localized, lastPart)
        } else {
            return String(format: "\("myHealthController.notification.update".localized), %@", dayMonthFormatted(), timeFormatted())
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

}
