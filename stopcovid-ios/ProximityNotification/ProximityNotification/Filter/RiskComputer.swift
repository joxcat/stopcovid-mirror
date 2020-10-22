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

final class RiskComputer {
    
    let deltas: [Double]
    
    let p0: Double
    
    let a: Double
    
    let timeWindow: TimeInterval
    
    let timeOverlap: TimeInterval
    
    init(deltas: [Double],
         p0: Double,
         a: Double,
         timeWindow: TimeInterval,
         timeOverlap: TimeInterval) {
        self.deltas = deltas
        self.p0 = p0
        self.a = a
        self.timeWindow = timeWindow
        self.timeOverlap = timeOverlap
    }
    
    func computeRisk(for timestampedRSSIs: [TimestampedRSSI], from epochStartDate: Date, withEpochDuration epochDuration: TimeInterval) -> [Double] {
        let timeSlot = timeWindow - timeOverlap
        
        guard epochDuration > 0.0, timeSlot > 0.0 else {
            return []
        }
        
        let timeSlotCount = Int(ceil(epochDuration / timeSlot))
        var groupedRSSIs = Array(repeating: [Int](), count: timeSlotCount)
        
        timestampedRSSIs.forEach { timestampedRSSI in
            let timestampDelta = timestampedRSSI.timestamp.timeIntervalSince1970 - epochStartDate.timeIntervalSince1970
            let timeSlotIndex = Int(floor(timestampDelta / timeSlot))
            if timeSlotIndex >= 0 && timeSlotIndex < timeSlotCount {
                groupedRSSIs[timeSlotIndex].append(timestampedRSSI.rssi)
            }
        }
        
        let windowTimeSlotCount = Int(ceil(timeWindow / timeSlot))
        let risks: [Double] = groupedRSSIs.indices.map { timeSlot in
            var rssis = [Int]()
            for index in timeSlot..<(timeSlot + windowTimeSlotCount) {
                if groupedRSSIs.indices.contains(index) {
                    rssis += groupedRSSIs[index]
                }
            }
            
            guard !rssis.isEmpty else {
                return 0.0
            }
            
            let softmaxRSSI = rssis.softmax(factor: a)
            let gamma = (softmaxRSSI - p0) / deltas[min(rssis.count - 1, deltas.count - 1)]
            let risk = min(1.0, max(0.0, gamma))
            
            return risk
        }
        
        return risks
    }
}
