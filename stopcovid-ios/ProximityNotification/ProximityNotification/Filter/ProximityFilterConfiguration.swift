/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/27 - for the TousAntiCovid project
 */

import Foundation

/// A configuration object that defines the behavior of a proximity filter.
public struct ProximityFilterConfiguration {
    
    /// RSSIs are kept if the duration of the period over which they were received exceeds this threshold. Default value is 5 minutes.
    public let durationThreshold: TimeInterval
    
    /// The threshold above which an RSSI value is clipped. Default value is 0 dBm. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    public let rssiThreshold: Int
    
    /// The threshold for the risk above which RSSIs are kept. Ranges from 0.0 to 1.0. Default value is 0.2. Has no effect if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    public let riskThreshold: Double
    
    /// An array used to weight the risk according to the number of RSSI values contained in a time slot. Default values are [39.0, 27.0, 23.0, 21.0, 20.0, 19.0, 18.0, 17.0, 16.0, 15.0]. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    public let deltas: [Double]
    
    /// The power below which a received RSSI value is considered to be zero risk, in dBm. Default value is -66 dBm. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    public let p0: Double
    
    /// A constant for the softmax function which is applied to the RSSIs when computing the intermediate risks. Default value is 4.342. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    public let a: Double
    
    /// A constant for the softmax function used to compute the risk. Default value is 0.1. Has no effect if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    public let b: Double
    
    /// The duration of the period over which a partial risk is computed.
    public let timeWindow: TimeInterval
    
    /// The duration of the period over which two successive time windows overlap.
    public let timeOverlap: TimeInterval
    
    /// Creates a configuration for a proximity filter.
    /// - Parameters:
    ///   - durationThreshold: RSSIs are kept if the duration of the period over which they were received exceeds this threshold. Default value is 5 minutes.
    ///   - rssiThreshold: The threshold above which an RSSI value is clipped. Default value is 0 dBm. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    ///   - riskThreshold: The threshold for the risk above which RSSIs are kept. Ranges from 0.0 to 1.0. Default value is 0.2. Has no effect if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    ///   - deltas: An array used to weight the risk according to the number of RSSI values contained in a time slot. Default values are [39.0, 27.0, 23.0, 21.0, 20.0, 19.0, 18.0, 17.0, 16.0, 15.0]. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    ///   - p0: The power below which a received RSSI value is considered to be zero risk, in dBm. Default value is -66 dBm. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    ///   - a: A constant for the softmax function which is applied to the RSSIs when computing the intermediate risks. Default value is 4.342. Has no effect if filtering mode is `ProximityFilterMode.Full`.
    ///   - b: A constant for the softmax function used to compute the risk. Default value is 0.1. Has no effect if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    ///   - timeWindow: The duration of the period over which a partial risk is computed. Default value is 2 minutes.
    ///   - timeOverlap: The duration of the period over which two successive time windows overlap. Default value is 1 minute.
    public init(durationThreshold: TimeInterval = 5.0 * 60.0,
                rssiThreshold: Int = 0,
                riskThreshold: Double = 0.2,
                deltas: [Double] = [39.0, 27.0, 23.0, 21.0, 20.0, 19.0, 18.0, 17.0, 16.0, 15.0],
                p0: Double = -66.0,
                a: Double = 10.0 / log(10.0),
                b: Double = 0.1,
                timeWindow: TimeInterval = 120.0,
                timeOverlap: TimeInterval = 60.0) {
        self.durationThreshold = durationThreshold
        self.rssiThreshold = rssiThreshold
        self.riskThreshold = riskThreshold
        self.deltas = deltas
        self.p0 = p0
        self.a = a
        self.b = b
        self.timeWindow = timeWindow
        self.timeOverlap = timeOverlap
    }
}
