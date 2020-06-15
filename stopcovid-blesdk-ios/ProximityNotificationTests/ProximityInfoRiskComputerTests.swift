/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the STOP-COVID project
 */

@testable import ProximityNotification
import XCTest

class ProximityInfoRiskComputerTests: XCTestCase {
    
    private let riskComputer = ProximityInfoRiskComputer()
    
    private let duration: TimeInterval = 16 * 60
    
    func testComputeRiskWithEmptyProximityInfosShouldReturnZeroRisk() throws {
        // Given
        let proximityInfos = [ProximityInfo]()
        let date = Date()
        let expectedRisk = ProximityInfoRisk(score: 0.0)
        
        // When
        let risk = riskComputer.computeRisk(for: proximityInfos, from: date, withDuration: duration)
        
        // Then
        XCTAssertEqual(expectedRisk.score, risk.score)
    }
    
    func testComputeRiskWithDatasetShouldReturnExpectedRisk() throws {
        (0...3).forEach { index in
            // Given
            guard let dataset = parseDataset(atIndex: index) else {
                XCTFail("Could not parse RiskComputerDataset.csv")
                return
            }
            
            // When
            let risk = riskComputer.computeRisk(for: dataset.proximityInfos, from: dataset.startDate, withDuration: duration)
            
            // Then
            XCTAssertEqual(dataset.risk.score, risk.score, accuracy: 0.0001)
        }
    }
    
    private func parseDataset(atIndex index: Int) -> Dataset? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "RiskComputerDataset", withExtension: "csv"),
            let data = try? Data(contentsOf: url),
            let dataset = String(bytes: data, encoding: .utf8),
            let proximityPayload = ProximityPayload(data: Data(repeating: 0, count: 16)) else {
                return nil
        }
        
        let minTimestamp = (duration - 60.0) * 1_000.0 * Double(index)
        let maxTimestamp = minTimestamp + duration * 1_000.0
        var proximityInfos = [ProximityInfo]()
        var scores = [Double]()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = ","
        
        let lines = dataset.split { $0.isNewline }
        lines.forEach { line in
            let values = line.split(separator: ";").map { String($0) }
            if values.count >= 6 {
                if let score = numberFormatter.number(from: values[5])?.doubleValue {
                    scores.append(score)
                }
            }
            
            if values.count >= 1,
                let calibratedRssi = numberFormatter.number(from: values[0])?.intValue,
                let timestamp = numberFormatter.number(from: values[1])?.doubleValue,
                timestamp >= minTimestamp && timestamp < maxTimestamp {
                let metadata = BluetoothProximityMetadata(rawRSSI: 0,
                                                          calibratedRSSI: calibratedRssi,
                                                          txPowerLevel: 0)
                let proximityInfo = ProximityInfo(payload: proximityPayload,
                                                  timestamp: Date(timeIntervalSince1970: timestamp / 1_000.0),
                                                  metadata: metadata)
                proximityInfos.append(proximityInfo)
            }
        }
        
        return index < scores.count ?  Dataset(proximityInfos: proximityInfos,
                                               startDate: Date(timeIntervalSince1970: minTimestamp / 1_000.0),
                                               risk: ProximityInfoRisk(score: scores[index])) : nil
    }
}

private extension ProximityInfoRiskComputerTests {
    
    struct Dataset {
        
        let proximityInfos: [ProximityInfo]
        
        let startDate: Date
        
        let risk: ProximityInfoRisk
    }
}
