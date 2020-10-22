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

/// A specification of the Bluetooth settings for proximity notification.
public struct BluetoothSettings {
    
    /// The unique identifier of the exposed Bluetooth service.
    public let serviceUniqueIdentifier: String
    
    /// The unique identifier of the characteristic used to exchange payloads through the exposed Bluetooth service.
    public let serviceCharacteristicUniqueIdentifier: String
    
    /// The compensation gain for the transmitting power level, in decibels. Conveyed by the transmitted Bluetooth proximity payload.
    public let txCompensationGain: Int8
    
    /// The compensation gain for the receiving power level, in decibels. Allows to compute the calibrated RSSI.
    public let rxCompensationGain: Int8
    
    /// The minimum time interval between two successive Bluetooth connections on the same peripheral. Default value is 10 seconds.
    public let connectionTimeInterval: TimeInterval
    
    /// The expiration delay for the received Bluetooth proximity information in cache. Default value is 30 minutes.
    public let cacheExpirationDelay: TimeInterval
    
    /// Creates a specification of Bluetooth settings with the specified values.
    /// - Parameters:
    ///   - serviceUniqueIdentifier: The unique identifier of the exposed Bluetooth service.
    ///   - serviceCharacteristicUniqueIdentifier: The unique identifier of the characteristic used to exchange payloads through the exposed Bluetooth service.
    ///   - txCompensationGain: The compensation gain for the transmitting power level, in decibels. Conveyed by the transmitted Bluetooth proximity payload.
    ///   - rxCompensationGain: The compensation gain for the receiving power level, in decibels. Allows to compute the calibrated RSSI.
    ///   - connectionTimeInterval: The minimum time interval between two successive Bluetooth connections on the same peripheral. Default value is 10 seconds.
    ///   - cacheExpirationDelay: The expiration delay for the received Bluetooth proximity information in cache. Default value is 30 minutes.
    public init(serviceUniqueIdentifier: String,
                serviceCharacteristicUniqueIdentifier: String,
                txCompensationGain: Int8,
                rxCompensationGain: Int8,
                connectionTimeInterval: TimeInterval = 10.0,
                cacheExpirationDelay: TimeInterval = 30.0 * 60.0) {
        self.serviceUniqueIdentifier = serviceUniqueIdentifier
        self.serviceCharacteristicUniqueIdentifier = serviceCharacteristicUniqueIdentifier
        self.txCompensationGain = txCompensationGain
        self.rxCompensationGain = rxCompensationGain
        self.connectionTimeInterval = connectionTimeInterval
        self.cacheExpirationDelay = cacheExpirationDelay
    }
}
