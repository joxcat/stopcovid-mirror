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

/// The possible states of proximity notification.
public enum ProximityNotificationState: Int {
    
    /// A state that indicates the proximity notification is on.
    case on
    
    /// A state that indicates the proximity notification is off.
    case off
    
    /// A state that indicates the application isn’t authorized to use proximity notification.
    case unauthorized
    
    /// A state that indicates this device doesn’t support the proximity notification.
    case unsupported
    
    /// The proximity notification state is unknown.
    case unknown
}

/// The identifier of a proximity notification payload.
public typealias ProximityPayloadIdentifier = Data

/// A handler that provides a proximity notification payload for this device.
/// - Returns: The payload.
public typealias ProximityPayloadProvider = () -> ProximityPayload?

/// A handler that returns an identifier for a given proximity notification payload.
/// - Parameter payload: The payload to compute the identifier from.
/// - Returns: The identifier.
public typealias IdentifierFromProximityPayload = (_ payload: ProximityPayload) -> ProximityPayloadIdentifier?

/// A handler called when proximity information has been updated.
/// - Parameter proximityInfo: The new proximity information.
public typealias ProximityInfoUpdateHandler = (_ proximityInfo: ProximityInfo) -> Void

/// A handler called when proximity notification state has changed.
/// - Parameters state: The new proximity notification state.
public typealias StateChangedHandler = (_ state: ProximityNotificationState) -> Void

/// The entry point to manage proximity notification.
final public class ProximityNotificationService {
    
    private let bluetoothProximityNotification: BluetoothProximityNotification
    
    /// The current proximity notification state.
    public var state: ProximityNotificationState {
        return bluetoothProximityNotification.state
    }
    
    /// Creates a proximity notification service with the specified settings, a state change handler and a logger.
    /// - Parameters:
    ///   - settings: The proximity notification settings.
    ///   - stateChangedHandler: A handler called when proximity notification state has changed.
    ///   - logger: The logger used in the service.
    public init(settings: ProximityNotificationSettings,
                stateChangedHandler: @escaping StateChangedHandler,
                logger: ProximityNotificationLoggerProtocol) {
        let logger = ProximityNotificationLogger(logger: logger)
        let dispatchQueue = DispatchQueue(label: UUID().uuidString)
        let centralManager = BluetoothCentralManager(settings: settings.bluetoothSettings,
                                                     dispatchQueue: dispatchQueue,
                                                     logger: logger)
        let peripheralManager = BluetoothPeripheralManager(settings: settings.bluetoothSettings,
                                                           dispatchQueue: dispatchQueue,
                                                           logger: logger)
        bluetoothProximityNotification = BluetoothProximityNotification(settings: settings.bluetoothSettings,
                                                                        stateChangedHandler: stateChangedHandler,
                                                                        dispatchQueue: dispatchQueue,
                                                                        centralManager: centralManager,
                                                                        peripheralManager: peripheralManager)
    }
    
    /// Creates a proximity notification service with the specified settings, a state change handler and a console logger.
    /// - Parameters:
    ///   - settings: The proximity notification settings.
    ///   - stateChangedHandler: A handler called when proximity notification state has changed.
    public convenience init(settings: ProximityNotificationSettings,
                            stateChangedHandler: @escaping StateChangedHandler) {
        self.init(settings: settings, stateChangedHandler: stateChangedHandler, logger: ProximityNotificationConsoleLogger())
    }
    
    deinit {
        stop()
    }
    
    /// Starts the proximity notification service.
    /// - Parameters:
    ///   - proximityPayloadProvider: A handler that provides a proximity notification payload for this device.
    ///   - proximityInfoUpdateHandler: A handler called when proximity information has been updated.
    ///   - identifierFromProximityPayload: A handler that returns an identifier for a given proximity notification payload.
    public func start(proximityPayloadProvider: @escaping ProximityPayloadProvider,
                      proximityInfoUpdateHandler: @escaping ProximityInfoUpdateHandler,
                      identifierFromProximityPayload: @escaping IdentifierFromProximityPayload) {
        bluetoothProximityNotification.start(proximityPayloadProvider: proximityPayloadProvider,
                                             proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                                             identifierFromProximityPayload: identifierFromProximityPayload)
    }
    
    /// Stops the proximity notification service.
    public func stop() {
        bluetoothProximityNotification.stop()
    }
}
