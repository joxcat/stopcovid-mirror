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

/// The risk associated with proximity information.
public struct ProximityInfoRisk {
    
    /// The risk level.
    ///
    /// - low: The level for a low risk.
    /// - medium: The level for a medium risk.
    /// - high: The level for a high risk.
    public enum Level {
        
        case low
        case medium
        case high
    }
    
    /// The risk score. Ranges from 0 to the number of minutes in the period over which the risk was computed.
    public let score: Double
    
    /// The risk level.
    public var level: Level {
        switch score {
        case 0..<3:
            return .low
        case 3..<7:
            return .medium
        default:
            return .high
        }
    }
    
    init(score: Double) {
        self.score = score
    }
}

/// An object that computes the risk associated with proximity information.
public final class ProximityInfoRiskComputer {
    
    /// Creates a risk computer.
    public init() {}
    
    /// Computes the risk associated with specified proximity information.
    /// - Parameters:
    ///   - proximityInfos: The proximity information.
    ///   - date: The start date to compute the risk from.
    ///   - duration: The period over which the risk will be computed.
    /// - Returns: The risk.
    public func computeRisk(for proximityInfos: [ProximityInfo], from date: Date, withDuration duration: TimeInterval) -> ProximityInfoRisk {
        guard duration > 0.0 else {
            return ProximityInfoRisk(score: 0.0)
        }
        
        // Initialization
        
        let durationInMinutes = Int(ceil(duration / 60.0))
        let deltas = [39.0, 27.0, 23.0, 21.0, 20.0, 15.0]
        let po = -66.0
        var groupedRssis = Array(repeating: [Int](), count: durationInMinutes)
        
        // Fading compensation
        
        let timestampedRssis: [(Int, Int)] = proximityInfos.compactMap { proximityInfo in
            guard let metadata = proximityInfo.metadata as? BluetoothProximityMetadata else {
                return nil
            }
            
            let timestampDelta = proximityInfo.timestamp.timeIntervalSince1970 - date.timeIntervalSince1970
            let minute = Int(floor(timestampDelta / 60.0))
            guard minute < durationInMinutes else {
                return nil
            }
            
            return (minute, metadata.calibratedRSSI)
        }
        
        timestampedRssis.forEach { minute, rssi in
            if minute < groupedRssis.count {
                groupedRssis[minute].append(rssi)
            }
        }
        
        // Average RSSI and risk scoring
        
        let range = 0..<(groupedRssis.count - 1)
        let score = range.reduce(0.0) { partialScore, minute in
            let rssis = groupedRssis[minute] + groupedRssis[minute + 1]
            guard !rssis.isEmpty else {
                return 0.0
            }
            
            let averageRssi = softmax(inputs: rssis)
            let gamma = (averageRssi - po) / deltas[min(rssis.count - 1, deltas.count - 1)]
            let risk = min(1.0, max(0.0, gamma))
            
            return partialScore + risk
        }
        
        return ProximityInfoRisk(score: score)
    }
    
    private func softmax(inputs: [Int]) -> Double {
        guard !inputs.isEmpty else {
            return 0.0
        }
        
        let a = 4.342
        let exponentialSum = inputs.reduce(0.0) { $0 + exp(Double($1) / a) }
        
        return a * log(exponentialSum / Double(inputs.count))
    }
}
