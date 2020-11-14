/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import Foundation
import os.log

/// The logger level used in the logger.
public enum ProximityNotificationLoggerLevel: Int {
    
    case debug, info, error, none
}

extension ProximityNotificationLoggerLevel: Comparable {
    
    public static func < (lhs: ProximityNotificationLoggerLevel, rhs: ProximityNotificationLoggerLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension ProximityNotificationLoggerLevel: CustomStringConvertible {
    
    /// The description to display the logger level.
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .none: return ""
        }
    }
}

/// The logger protocol to build a custom logger.
public protocol ProximityNotificationLoggerProtocol {
    
    /// The minimum log level. The log level of a new log must be greater than it to be displayed.
    var minimumLogLevel: ProximityNotificationLoggerLevel { get set }
    
    /// Logs a new event with a message for a log level.
    /// - Parameters:
    ///   - logLevel: The log level of the log.
    ///   - message: The message to log.
    ///   - source: The log source.
    func log(logLevel: ProximityNotificationLoggerLevel, message: @autoclosure () -> String, source: @autoclosure () -> String)
}

class ProximityNotificationConsoleLogger: ProximityNotificationLoggerProtocol {
    
    #if DEBUG
    var minimumLogLevel: ProximityNotificationLoggerLevel = .debug
    #else
    var minimumLogLevel: ProximityNotificationLoggerLevel = .none
    #endif
    
    init() {}
    
    func log(logLevel: ProximityNotificationLoggerLevel, message: @autoclosure () -> String, source: @autoclosure () -> String) {
        guard logLevel != .none else { return }
        
        var logType: OSLogType = .default
        switch logLevel {
        case .debug:
            logType = .debug
        case .info:
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
    
    func debug(message: @autoclosure () -> String, source: @autoclosure () -> String) {
        log(logLevel: .debug, message: message(), source: source())
    }
    
    func info(message: @autoclosure () -> String, source: @autoclosure () -> String) {
        log(logLevel: .info, message: message(), source: source())
    }
    
    func error(message: @autoclosure () -> String, source: @autoclosure () -> String) {
        log(logLevel: .error, message: message(), source: source())
    }
    
    private func log(logLevel: ProximityNotificationLoggerLevel, message: @autoclosure () -> String, source: @autoclosure () -> String) {
        if logLevel >= logger.minimumLogLevel {
            logger.log(logLevel: logLevel, message: message(), source: source())
        }
    }
}
