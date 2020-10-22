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

/// An object that filters proximity information.
final public class ProximityFilter {
    
    /// A configuration object that defines the behavior of the proximity filter.
    public let configuration: ProximityFilterConfiguration
    
    /// Creates a proximity filter.
    /// - Parameter configuration: A configuration object that defines the behavior of the proximity filter.
    public init(configuration: ProximityFilterConfiguration) {
        self.configuration = configuration
    }
    
    /// Filters the specified received signal strength indicators and computes some relevant output values.
    ///
    /// If filtering is successful, the content of the output value depends on the selected mode:
    /// - If selected mode is `ProximityFilterMode.Full`, the output value contains the sorted list of the specified timestamped RSSIs.
    /// - If selected mode is `ProximityFilterMode.Medium`, the output value contains the sorted list of the specified timestamped RSSIs, with potentially updated RSSI values. It also contains the associated risks for each time window, the mean value of clipped RSSI peaks, and the number of clipped RSSI peaks.
    /// - If selected mode is `ProximityFilterMode.Risks`, the output value contains the sorted list of the specified timestamped RSSIs, with potentially updated RSSI values. It also contains the associated risks for each time window, the mean value of clipped RSSI peaks, the number of clipped RSSI peaks, as well as the intermediate risk computed from the window risks, the risk computed from the intermediate risk, the duration of the period over which the RSSIs where received and the risk density.
    ///
    /// - Parameters:
    ///   - timestampedRSSIs: The timestamped RSSIs to filter.
    ///   - epochStartDate: The start date of the period over which the RSSIs were gathered.
    ///   - epochDuration: The duration of the period over which the RSSIs were gathered.
    ///   - mode: The filtering mode.
    /// - Returns: The filtering result.
    public func filterRSSIs(_ timestampedRSSIs: [TimestampedRSSI],
                            from epochStartDate: Date,
                            withEpochDuration epochDuration: TimeInterval,
                            mode: ProximityFilterMode) -> Result<ProximityFilterOutput, ProximityFilterError> {
        let sortedTimestampedRSSIs = timestampedRSSIs.sorted { $0.timestamp < $1.timestamp }
        let firstTimestamp = sortedTimestampedRSSIs.first?.timestamp.timeIntervalSince1970 ?? 0
        let lastTimestamp = sortedTimestampedRSSIs.last?.timestamp.timeIntervalSince1970 ?? 0
        
        guard !timestampedRSSIs.isEmpty,
            lastTimestamp - firstTimestamp >= Double(configuration.durationThreshold) else {
                return .failure(.durationTooShort)
        }
        
        let result: Result<ProximityFilterOutput, ProximityFilterError>
        
        if mode == .full {
            result = .success(ProximityFilterOutput(timestampedRSSIs: sortedTimestampedRSSIs, areTimestampedRSSIsUpdated: false))
        } else {
            let rssiClipper = RSSIClipper(threshold: configuration.rssiThreshold)
            let riskComputer = RiskComputer(deltas: configuration.deltas,
                                            p0: configuration.p0,
                                            a: configuration.a,
                                            timeWindow: configuration.timeWindow,
                                            timeOverlap: configuration.timeOverlap)
            
            let clipOutput = rssiClipper.clipRSSIs(sortedTimestampedRSSIs)
            let windowRisks = riskComputer.computeRisk(for: clipOutput.clippedTimestampedRSSIs,
                                                       from: epochStartDate,
                                                       withEpochDuration: epochDuration)
            
            let timestampedRSSIs = clipOutput.clippedTimestampedRSSIs
            let areTimestampedRSSIsUpdated = !clipOutput.peaks.isEmpty
            let meanPeak = clipOutput.peaks.mean()
            let peakCount = clipOutput.peaks.count
            
            if mode == .medium {
                result = .success(ProximityFilterOutput(timestampedRSSIs: timestampedRSSIs,
                                                        areTimestampedRSSIsUpdated: areTimestampedRSSIsUpdated,
                                                        windowRisks: windowRisks,
                                                        meanPeak: meanPeak,
                                                        peakCount: peakCount))
            } else {
                let intermediateRisk = windowRisks.softmax(factor: configuration.b)
                let durationInMinutes = (lastTimestamp - firstTimestamp) / 60.0
                let riskDensity = windowRisks.filter { $0 > 0 }.count
                let risk = intermediateRisk * (durationInMinutes + Double(riskDensity)) / Double(2 * windowRisks.count)
                
                if risk < configuration.riskThreshold {
                    result = .failure(.riskTooLow)
                } else {
                    result = .success(ProximityFilterOutput(timestampedRSSIs: timestampedRSSIs,
                                                            areTimestampedRSSIsUpdated: areTimestampedRSSIsUpdated,
                                                            windowRisks: windowRisks,
                                                            meanPeak: meanPeak,
                                                            peakCount: peakCount,
                                                            intermediateRisk: intermediateRisk,
                                                            risk: risk,
                                                            durationInMinutes: durationInMinutes,
                                                            riskDensity: riskDensity))
                }
            }
        }
        
        return result
    }
}
