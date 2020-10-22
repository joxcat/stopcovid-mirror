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

class ProximityPayloadTests: XCTestCase {
    
    func testInitWithDataSucceeds() {
        // Given
        let data = Data(Array(0..<16))
        
        // When
        let proximityPayload = ProximityPayload(data: data)
        
        // Then
        XCTAssertNotNil(proximityPayload)
        if let proximityPayload = proximityPayload {
            XCTAssertEqual(data, proximityPayload.data)
        }
    }
    
    func testInitWithTruncatedDataFails() {
        // Given
        let data = Data(Array(0..<15))
        
        // When
        let proximityPayload = ProximityPayload(data: data)
        
        // Then
        XCTAssertNil(proximityPayload)
    }
    
    func testInitWithDataOverflowFails() {
        // Given
        let data = Data(Array(0..<17))
        
        // When
        let proximityPayload = ProximityPayload(data: data)
        
        // Then
        XCTAssertNil(proximityPayload)
    }
}
