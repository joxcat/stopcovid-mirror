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

final class RSSIClipper {
    
    let threshold: Int
    
    init(threshold: Int) {
        self.threshold = threshold
    }
    
    func clipRSSIs(_ sortedTimestampedRSSIs: [TimestampedRSSI]) -> RSSIClipperOutput {
        var peaks = [Int]()
        var clippedTimestampedRSSIs = [TimestampedRSSI]()
        clippedTimestampedRSSIs.reserveCapacity(sortedTimestampedRSSIs.count)
        sortedTimestampedRSSIs
            .enumerated()
            .forEach { offset, timestampedRSSI in
                let currentRSSI = timestampedRSSI.rssi
                if currentRSSI > threshold {
                    peaks.append(currentRSSI)
                    let previousRSSI = offset == 0 ? currentRSSI : clippedTimestampedRSSIs[offset - 1].rssi
                    let nextRSSI = offset == sortedTimestampedRSSIs.count - 1 ? currentRSSI : sortedTimestampedRSSIs[offset + 1].rssi
                    let updatedRSSI = min(min(previousRSSI, nextRSSI), threshold)
                    clippedTimestampedRSSIs.append(TimestampedRSSI(rssi: updatedRSSI,
                                                                   identifier: timestampedRSSI.identifier,
                                                                   timestamp: timestampedRSSI.timestamp))
                } else {
                    clippedTimestampedRSSIs.append(timestampedRSSI)
                }
        }
        
        return RSSIClipperOutput(clippedTimestampedRSSIs: clippedTimestampedRSSIs, peaks: peaks)
    }
}
