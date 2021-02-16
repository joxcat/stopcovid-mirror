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

class CacheTests: XCTestCase {
    
    func testSetValueSucceeds() {
        // Given
        let cache = Cache<UUID, BluetoothPeripheral>()
        let firstKey = UUID()
        let secondKey = UUID()
        let firstValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 12, isRSSIFromPayload: false)
        let secondValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 34, isRSSIFromPayload: false)
        
        // When
        cache[firstKey] = firstValue
        cache.setValue(secondValue, forKey: secondKey)
        
        // Then
        XCTAssertEqual(firstValue, cache[firstKey])
        XCTAssertEqual(firstValue, cache.value(forKey: firstKey))
        XCTAssertEqual(secondValue, cache[secondKey])
        XCTAssertEqual(secondValue, cache.value(forKey: secondKey))
    }
    
    func testRemoveValueSucceeds() {
        // Given
        let cache = Cache<UUID, BluetoothPeripheral>()
        let firstKey = UUID()
        let secondKey = UUID()
        let firstValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 12, isRSSIFromPayload: false)
        let secondValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 34, isRSSIFromPayload: false)
        cache[firstKey] = firstValue
        cache[secondKey] = secondValue
        
        // When
        cache[firstKey] = nil
        cache.removeValue(forKey: secondKey)
        
        // Then
        XCTAssertNil(cache[firstKey])
        XCTAssertNil(cache[secondKey])
    }
    
    func testRemoveAllValuesSucceeds() {
        // Given
        let cache = Cache<UUID, BluetoothPeripheral>()
        let firstKey = UUID()
        let secondKey = UUID()
        let firstValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 12, isRSSIFromPayload: false)
        let secondValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 34, isRSSIFromPayload: false)
        cache[firstKey] = firstValue
        cache[secondKey] = secondValue
        
        // When
        cache.removeAllValues()
        
        // Then
        XCTAssertNil(cache[firstKey])
        XCTAssertNil(cache[secondKey])
    }
    
    func testExpiredValueReturnsNil() {
        // Given
        let cache = Cache<UUID, BluetoothPeripheral>(expirationDelay: 5)
        let expiredKey = UUID()
        let validKey = UUID()
        let expiredValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 12, isRSSIFromPayload: false)
        let validValue = BluetoothPeripheral(peripheralIdentifier: UUID(), timestamp: Date(), rssi: 34, isRSSIFromPayload: false)
        cache[expiredKey] = expiredValue
        
        // When
        sleep(2)
        cache[validKey] = validValue
        sleep(3)
        
        // Then
        XCTAssertNil(cache[expiredKey])
        XCTAssertEqual(validValue, cache[validKey])
    }
}
