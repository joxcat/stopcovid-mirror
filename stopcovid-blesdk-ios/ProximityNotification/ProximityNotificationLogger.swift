/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the STOP-COVID project
 */

import Foundation
import os.log

enum ProximityNotificationLoggerLevel: Int {
    
    case debug, info, warning, error, none
}

extension ProximityNotificationLoggerLevel: Comparable {
    
    static func < (lhs: ProximityNotificationLoggerLevel, rhs: ProximityNotificationLoggerLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension ProximityNotificationLoggerLevel: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .none: return ""
        }
    }
}

protocol ProximityNotificationLoggerProtocol {
    
    var minimumLogLevel: ProximityNotificationLoggerLevel { get set }
    
    func log(logLevel: ProximityNotificationLoggerLevel,
             _ message: @autoclosure () -> String,
             file: String,
             line: Int,
             function: String)
}

class ProximityNotificationConsoleLogger: ProximityNotificationLoggerProtocol {
    
    #if DEBUG
    var minimumLogLevel: ProximityNotificationLoggerLevel = .debug
    #else
    var minimumLogLevel: ProximityNotificationLoggerLevel = .none
    #endif
    
    init() {}
    
    func log(logLevel: ProximityNotificationLoggerLevel, _ message: () -> String, file: String, line: Int, function: String) {
        guard logLevel != .none else { return }
        
        var logType: OSLogType = .default
        switch logLevel {
        case .debug:
            logType = .debug
        case .info, .warning:
            logType = .info
        case .error:
            logType = .error
        default:
            break
        }
        
        os_log("%{public}@",
               log: OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: "proximitynotification"),
               type: logType,
               message())
    }
}

class ProximityNotificationLogger {
        
    private let logger: ProximityNotificationLoggerProtocol
        
    init(logger: ProximityNotificationLoggerProtocol) {
        self.logger = logger
    }

    func log(logLevel: ProximityNotificationLoggerLevel, _ message: @autoclosure () -> String, file: String = #file, line: Int = #line, function: String = #function) {
        if logLevel >= logger.minimumLogLevel {
            logger.log(logLevel: logLevel, message(), file: file, line: line, function: function)
        }
    }
}
