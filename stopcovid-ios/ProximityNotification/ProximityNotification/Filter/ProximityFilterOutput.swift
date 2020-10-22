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

/// The output of a proximity filter.
public struct ProximityFilterOutput: Equatable {
    
    /// The list of filtered timestamped RSSIs. If `areTimestampedRSSIsUpdated` is `true`, then some of the timestamped RSSIs have been updated.
    public let timestampedRSSIs: [TimestampedRSSI]
    
    /// A boolean value indicating whether some of the filtered timestamped RSSIs have been updated.
    public let areTimestampedRSSIsUpdated: Bool
    
    /// The risks computed for each time window, or `nil` if filtering mode is `ProximityFilterMode.Full`.
    public let windowRisks: [Double]?
    
    /// The mean value of clipped RSSI peaks, or `nil` if filtering mode is `ProximityFilterMode.Full`.
    public let meanPeak: Double?
    
    /// The number of clipped RSSI peaks, or `nil` if filtering mode is `ProximityFilterMode.Full`.
    public let peakCount: Int?
    
    /// The intermediate risk, or `nil` if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    public let intermediateRisk: Double?
    
    /// The risk, or `nil` if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    public let risk: Double?
    
    /// The duration of the period over which the RSSIs where received, in minutes, or `nil` if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    public let durationInMinutes: Double?
    
    /// The risk density, or `nil` if filtering mode is `ProximityFilterMode.Full` or `ProximityFilterMode.Medium`.
    public let riskDensity: Int?
    
    init(timestampedRSSIs: [TimestampedRSSI],
         areTimestampedRSSIsUpdated: Bool,
         windowRisks: [Double]? = nil,
         meanPeak: Double? = nil,
         peakCount: Int? = nil,
         intermediateRisk: Double? = nil,
         risk: Double? = nil,
         durationInMinutes: Double? = nil,
         riskDensity: Int? = nil) {
        self.timestampedRSSIs = timestampedRSSIs
        self.areTimestampedRSSIsUpdated = areTimestampedRSSIsUpdated
        self.windowRisks = windowRisks
        self.meanPeak = meanPeak
        self.peakCount = peakCount
        self.intermediateRisk = intermediateRisk
        self.risk = risk
        self.durationInMinutes = durationInMinutes
        self.riskDensity = riskDensity
    }
}
