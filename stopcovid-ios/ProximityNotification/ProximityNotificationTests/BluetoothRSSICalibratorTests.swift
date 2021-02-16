/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/11/10 - for the TousAntiCovid project
 */

@testable import ProximityNotification
import XCTest

class BluetoothRSSICalibratorTests: XCTestCase {

    private let settings = BluetoothSettings(serviceUniqueIdentifier: UUID().uuidString,
                                             serviceCharacteristicUniqueIdentifier: UUID().uuidString,
                                             txCompensationGain: 10,
                                             rxCompensationGain: 20,
                                             connectionTimeInterval: 3)

    func testCalibratedRSSIWithRawRSSIInScan() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }

        let rssiCalibrator = BluetoothRSSICalibrator(settings: settings)
        let bluetoothPeripheral = BluetoothPeripheral(peripheralIdentifier: UUID(),
                                                      timestamp: Date(),
                                                      rssi: -30,
                                                      isRSSIFromPayload: false)
        let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: 25)

        // When
        let calibratedRSSI = rssiCalibrator.calibrateRSSI(for: bluetoothPeripheral,
                                                          from: bluetoothProximityPayload)

        // Then
        XCTAssertEqual(-75, calibratedRSSI)
    }

    func testCalibratedRSSIWithoutRawRSSI() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }

        let rssiCalibrator = BluetoothRSSICalibrator(settings: settings)
        let bluetoothPeripheral = BluetoothPeripheral(peripheralIdentifier: UUID(),
                                                      timestamp: Date(),
                                                      rssi: nil,
                                                      isRSSIFromPayload: false)
        let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: 25)

        // When
        let calibratedRSSI = rssiCalibrator.calibrateRSSI(for: bluetoothPeripheral,
                                                          from: bluetoothProximityPayload)

        // Then
        XCTAssertNil(calibratedRSSI)
    }

    func testCalibratedRSSIWithRawRSSIInPayload() {
        // Given
        guard let proximityPayload = ProximityPayload(data: Data(Array(0..<16))) else {
            XCTFail("Could not initialize ProximityPayload")
            return
        }

        let rssiCalibrator = BluetoothRSSICalibrator(settings: settings)
        let bluetoothPeripheral = BluetoothPeripheral(peripheralIdentifier: UUID(),
                                                      timestamp: Date(),
                                                      rssi: -30,
                                                      isRSSIFromPayload: true)
        let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload, txPowerLevel: 25)

        // When
        let calibratedRSSI = rssiCalibrator.calibrateRSSI(for: bluetoothPeripheral,
                                                          from: bluetoothProximityPayload)

        // Then
        XCTAssertEqual(-40, calibratedRSSI)
    }
}
