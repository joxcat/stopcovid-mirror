// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  URLResponse+SVExtension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 01/06/2020 - for the TousAntiCovid project.
//

import Foundation

extension URLResponse {
    
    var svStatusCode: Int? {
        (self as? HTTPURLResponse)?.statusCode
    }
    
    var svIsError: Bool? {
        guard let statusCode = svStatusCode else { return nil }
        return "\(statusCode)".first != "2"
    }
    
    var serverTime: Double {
        guard let dateString = (self as? HTTPURLResponse)?.allHeaderFields["Date"] as? String else { return Date().timeIntervalSince1970 }
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.shortWeekdaySymbols = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
        return dateFormatter.date(from: dateString)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    }
    
}
