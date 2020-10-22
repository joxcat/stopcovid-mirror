/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

@testable import ProximityNotification
import XCTest

class RiskComputerTests: XCTestCase {
    
    private let riskComputer = RiskComputer(deltas: [39.0, 27.0, 23.0, 21.0, 20.0, 19.0, 18.0, 17.0, 16.0, 15.0],
                                            p0: -66.0,
                                            a: 10.0 / log(10.0),
                                            timeWindow: 120.0,
                                            timeOverlap: 60.0)
    
    private let epochDuration: TimeInterval = 15.0 * 60.0
    
    func testComputeRiskWithDurationEqualToZeroShouldReturnEmptyRisk() throws {
        // Given
        let timestampedRSSIs = [TimestampedRSSI(rssi: -40, identifier: "", timestamp: Date())]
        
        // When
        let output = riskComputer.computeRisk(for: timestampedRSSIs, from: Date(), withEpochDuration: 0.0)
        
        // Then
        XCTAssertTrue(output.isEmpty)
    }
    
    func testComputeRiskWithEmptyTimestampedRSSIsShouldReturnZeroRisk() throws {
        // Given
        let timestampedRSSIs = [TimestampedRSSI]()
        
        // When
        let output = riskComputer.computeRisk(for: timestampedRSSIs, from: Date(), withEpochDuration: epochDuration)
        
        // Then
        XCTAssertEqual(Array(repeating: 0.0, count: 15), output)
    }
    
    func testComputeRiskWithOneTimestampedRSSIBeforeEpochStartDateShouldReturnZeroRisk() throws {
        // Given
        let epochStartDate = Date()
        let timestamp = Date(timeInterval: -1.0, since: epochStartDate)
        let timestampedRSSIs = [TimestampedRSSI(rssi: -40, identifier: "", timestamp: timestamp)]
        
        // When
        let output = riskComputer.computeRisk(for: timestampedRSSIs, from: epochStartDate, withEpochDuration: epochDuration)
        
        // Then
        XCTAssertEqual(Array(repeating: 0.0, count: 15), output)
    }
    
    func testComputeRiskWithOneTimestampedRSSIAfterEpochEndDateShouldReturnZeroRisk() throws {
        // Given
        let epochStartDate = Date()
        let timestamp = Date(timeInterval: epochDuration + 1.0, since: epochStartDate)
        let timestampedRSSIs = [TimestampedRSSI(rssi: -40, identifier: "", timestamp: timestamp)]
        
        // When
        let output = riskComputer.computeRisk(for: timestampedRSSIs, from: epochStartDate, withEpochDuration: epochDuration)
        
        // Then
        XCTAssertEqual(Array(repeating: 0.0, count: 15), output)
    }
}
