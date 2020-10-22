/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/06/03 - for the TousAntiCovid project
 */

@testable import ProximityNotification
import XCTest

class RSSIClipperTests: XCTestCase {
    
    func testClipRSSIsWithEmptyTimestampedRSSIsShouldReturnEmptyOutput() throws {
        // Given
        let rssiClipper = RSSIClipper(threshold: 0)
        let timestampedRSSIs = [TimestampedRSSI]()
        
        // When
        let output = rssiClipper.clipRSSIs(timestampedRSSIs)
        
        // Then
        XCTAssertTrue(output.clippedTimestampedRSSIs.isEmpty)
        XCTAssertTrue(output.peaks.isEmpty)
    }
    
    func testClipRSSIsWithDatasetShouldReturnExpectedOutput() {
        let parameterizedData = [ParameterizedData(rssis: [0], threshold: 0, expectedRSSIs: [0], expectedPeaks: []),
                                 ParameterizedData(rssis: [1], threshold: 0, expectedRSSIs: [0], expectedPeaks: [1]),
                                 ParameterizedData(rssis: [1, 2, 3], threshold: 0, expectedRSSIs: [0, 0, 0], expectedPeaks: [1, 2, 3]),
                                 ParameterizedData(rssis: [1, -20], threshold: 0, expectedRSSIs: [-20, -20], expectedPeaks: [1]),
                                 ParameterizedData(rssis: [-20, 1], threshold: 0, expectedRSSIs: [-20, -20], expectedPeaks: [1])]
        
        parameterizedData.forEach { parameterizedData in
            // Given
            let rssiClipper = RSSIClipper(threshold: parameterizedData.threshold)
            
            // When
            let output = rssiClipper.clipRSSIs(parameterizedData.timestampedRSSIs)
            
            // Then
            XCTAssertEqual(parameterizedData.expectedOutput.clippedTimestampedRSSIs, output.clippedTimestampedRSSIs)
            XCTAssertEqual(parameterizedData.expectedOutput.peaks, output.peaks)
        }
    }
}

extension RSSIClipperTests {
    
    private struct ParameterizedData {
        
        let timestampedRSSIs: [TimestampedRSSI]
        
        let threshold: Int
        
        let expectedOutput: RSSIClipperOutput
        
        init(rssis: [Int],
             threshold: Int,
             expectedRSSIs: [Int],
             expectedPeaks: [Int]) {
            let timestamp = Date()
            timestampedRSSIs = rssis.map { TimestampedRSSI(rssi: $0, identifier: "", timestamp: timestamp) }
            self.threshold = threshold
            let expectedTimestampedRSSIs = expectedRSSIs.map { TimestampedRSSI(rssi: $0, identifier: "", timestamp: timestamp) }
            expectedOutput = RSSIClipperOutput(clippedTimestampedRSSIs: expectedTimestampedRSSIs, peaks: expectedPeaks)
        }
    }
}
