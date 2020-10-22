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

class ProximityFilterTests: XCTestCase {
    
    private let epochStartDate = Date(timeIntervalSince1970: 0)
    
    private let epochDuration = 15.0 * 60.0
    
    func testFilterRSSIsWithEmptyTimestampedRSSIsShouldReturnFailure() throws {
        // Given
        let timestampedRSSIs = [TimestampedRSSI]()
        let proximityFilter = ProximityFilter(configuration: ProximityFilterConfiguration())
        
        // When
        let result = proximityFilter.filterRSSIs(timestampedRSSIs,
                                                 from: epochStartDate,
                                                 withEpochDuration: epochDuration,
                                                 mode: .full)
        
        // Then
        XCTAssertEqual(.failure(.durationTooShort), result)
    }
    
    func testFilterRSSIsInFullModeShouldReturnExpectedResult() throws {
        let dataSet = parseTimestampedRSSIDataSet()
        let parameterizedData = [ParameterizedData(input: Input(dataSet: dataSet, durationThreshold: 2.0 * 60.0),
                                                   expectedOutput: ExpectedOutput()),
                                 ParameterizedData(input: Input(dataSet: dataSet, durationThreshold: 5.0 * 60.0),
                                                   expectedOutput: ExpectedOutput()),
                                 ParameterizedData(input: Input(dataSet: dataSet, durationThreshold: 14.0 * 60.0),
                                                   expectedOutput: ExpectedOutput()),
                                 ParameterizedData(input: Input(dataSet: dataSet, durationThreshold: 15.0 * 60.0),
                                                   expectedOutput: ExpectedOutput(error: .durationTooShort))]
        
        parameterizedData.forEach { parameterizedData in
            // Given
            let proximityFilter = ProximityFilter(configuration: parameterizedData.configuration)
            
            // When
            let result = proximityFilter.filterRSSIs(parameterizedData.timestampedRSSIs,
                                                     from: epochStartDate,
                                                     withEpochDuration: epochDuration,
                                                     mode: .full)
            
            // Then
            XCTAssertEqual(parameterizedData.expectedResult, result)
        }
    }
    
    func testFilterRSSIsInMediumModeShouldReturnExpectedResult() throws {
        let dataSet = parseTimestampedRSSIDataSet()
        let windowRisks = [[0.22223279, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01226278, 0.096550071, 0.118937533, 0.121459094, 0.060818523, 0.0287871, 0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.076291313, 0.095690344, 0.090033589, 0.044448579, 0.013257903, 0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01226278, 0.096550071, 0.118937533, 0.121459094, 0.060818523, 0.0287871, 0.0, 0.0, 0.0]]
        let parameterizedData = [ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[0], meanPeak: -15.0, peakCount: 1)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, a: 10.0),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[1], meanPeak: -15.0, peakCount: 1)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, p0: -55.0),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[2], meanPeak: -15.0, peakCount: 1)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -60),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[3], meanPeak: -41.0, peakCount: 3))]
        
        parameterizedData.forEach { parameterizedData in
            // Given
            let proximityFilter = ProximityFilter(configuration: parameterizedData.configuration)
            
            // When
            let result = proximityFilter.filterRSSIs(parameterizedData.timestampedRSSIs,
                                                     from: epochStartDate,
                                                     withEpochDuration: epochDuration,
                                                     mode: .medium)
            
            // Then
            assertEqual(parameterizedData.expectedResult, result, riskAccuracy: 0.0001)
        }
    }
    
    func testFilterRSSIsInRisksModeShouldReturnExpectedResult() throws {
        let dataSet = parseTimestampedRSSIDataSet()
        let windowRisks = [[0.22223279, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01226278, 0.096550071, 0.118937533, 0.121459094, 0.060818523, 0.0287871, 0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.076291313, 0.095690344, 0.090033589, 0.044448579, 0.013257903, 0.0, 0.0, 0.0],
                           [0.22223279, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01226278, 0.096550071, 0.118937533, 0.121459094, 0.060818523, 0.0287871, 0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                           [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01226278, 0.096550071, 0.118937533, 0.121459094, 0.060818523, 0.0287871, 0.0, 0.0, 0.0],
                           [0.82223279, 0.00044885, 0.0, 0.165984332, 0.279341285, 0.365483185, 0.61226278, 0.696550071, 0.718937533, 0.721459094, 0.660818523, 0.6287871, 0.555474001, 0.321603449, 0.041594884]]
        let parameterizedData = [ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[0], meanPeak: -15.0, peakCount: 1, intermediateRisk: 0.056330584, risk: 0.041121327, durationInMinutes: 14.9, riskDensity: 7)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, a: 10.0),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[1], meanPeak: -15.0, peakCount: 1, intermediateRisk: 0.024608374, risk: 0.016323555, durationInMinutes: 14.9, riskDensity: 5)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, b: 0.1),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[2], meanPeak: -15.0, peakCount: 1, intermediateRisk: 0.071978844, risk: 0.052544556, durationInMinutes: 14.9, riskDensity: 7)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, p0: -55.0),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[3], meanPeak: -15.0, peakCount: 1, intermediateRisk: 0.0, risk: 0.0, durationInMinutes: 14.9, riskDensity: 0)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -60),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[4], meanPeak: -41.0, peakCount: 3, intermediateRisk: 0.034699744, risk: 0.024174155, durationInMinutes: 14.9, riskDensity: 6)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, riskThreshold: 0.2),
                                                   expectedOutput: ExpectedOutput(error: .riskTooLow)),
                                 ParameterizedData(input: Input(dataSet: dataSet, rssiThreshold: -35, riskThreshold: 0.2, p0: -75.0),
                                                   expectedOutput: ExpectedOutput(windowRisks: windowRisks[5], meanPeak: -15.0, peakCount: 1, intermediateRisk: 0.582083943, risk: 0.560740866, durationInMinutes: 14.9, riskDensity: 14))]
        
        parameterizedData.forEach { parameterizedData in
            // Given
            let proximityFilter = ProximityFilter(configuration: parameterizedData.configuration)
            
            // When
            let result = proximityFilter.filterRSSIs(parameterizedData.timestampedRSSIs,
                                                     from: epochStartDate,
                                                     withEpochDuration: epochDuration,
                                                     mode: .risks)
            
            // Then
            assertEqual(parameterizedData.expectedResult, result, riskAccuracy: 0.0001)
        }
    }
    
    func testFilterRSSIsPerformance() {
        let proximityFilter = ProximityFilter(configuration: ProximityFilterConfiguration())
        let duration = 14.0 * 24.0 * 60.0 * 60.0
        let filterCount = 700
        let timestampedRSSICountPerMinute = 100
        var timestampedRSSIs = Array(repeating: [TimestampedRSSI](), count: filterCount)
        var epochStartDates = [Date]()
        srand48(123)
        for filterIndex in 0..<filterCount {
            let epochStartDate = Date(timeIntervalSinceNow: duration * (1.0 - drand48()))
            epochStartDates.append(epochStartDate)
            for _ in 0..<Int((Double(timestampedRSSICountPerMinute) * epochDuration / 60.0)) {
                let rssi = Int(-255.0 * drand48())
                let identifier = filterIndex
                let timestamp = Date(timeInterval: epochDuration * drand48(), since: epochStartDate)
                timestampedRSSIs[filterIndex].append(TimestampedRSSI(rssi: rssi, identifier: identifier, timestamp: timestamp))
            }
            timestampedRSSIs[filterIndex].sort(by: { $0.timestamp < $1.timestamp })
        }
        
        measure {
            for index in 0..<filterCount {
                _ = proximityFilter.filterRSSIs(timestampedRSSIs[index],
                                                from: epochStartDates[index],
                                                withEpochDuration: epochDuration,
                                                mode: .risks)
            }
        }
    }
    
    private func assertEqual(_ result1: Result<ProximityFilterOutput, ProximityFilterError>,
                             _ result2: Result<ProximityFilterOutput, ProximityFilterError>,
                             riskAccuracy: Double) {
        switch result2 {
        case .success(let output):
            let expectedOutput = try? result1.get()
            XCTAssertNotNil(expectedOutput)
            if let expectedOutput = expectedOutput {
                XCTAssertEqual(expectedOutput.timestampedRSSIs, output.timestampedRSSIs)
                XCTAssertEqual(expectedOutput.areTimestampedRSSIsUpdated, output.areTimestampedRSSIsUpdated)
                XCTAssertEqual(expectedOutput.windowRisks?.count, output.windowRisks?.count)
                output.windowRisks?.enumerated().forEach { offset, windowRisk in
                    if let expectedWindowRisks = expectedOutput.windowRisks,
                        offset < expectedWindowRisks.count {
                        XCTAssertEqual(expectedWindowRisks[offset], windowRisk, accuracy: riskAccuracy)
                    }
                }
                XCTAssertEqual(expectedOutput.meanPeak, output.meanPeak)
                XCTAssertEqual(expectedOutput.peakCount, output.peakCount)
                if let expectedIntermediateRisk = expectedOutput.intermediateRisk,
                    let intermediateRisk = output.intermediateRisk {
                    XCTAssertEqual(expectedIntermediateRisk, intermediateRisk, accuracy: riskAccuracy)
                } else {
                    XCTAssertEqual(expectedOutput.intermediateRisk, output.intermediateRisk)
                }
                if let expectedRisk = expectedOutput.risk,
                    let risk = output.risk {
                    XCTAssertEqual(expectedRisk, risk, accuracy: riskAccuracy)
                } else {
                    XCTAssertEqual(expectedOutput.risk, output.risk)
                }
                XCTAssertEqual(expectedOutput.durationInMinutes, output.durationInMinutes)
                XCTAssertEqual(expectedOutput.riskDensity, output.riskDensity)
            }
        case .failure(let error):
            var expectedError: ProximityFilterError?
            do {
                _ = try result1.get()
            } catch let error {
                expectedError = error as? ProximityFilterError
            }
            XCTAssertEqual(expectedError, error)
        }
    }
    
    private func parseTimestampedRSSIDataSet() -> TimestampedRSSIDataSet {
        guard let url = Bundle(for: type(of: self)).url(forResource: "TimestampedRSSIDataSet", withExtension: "csv"),
            let data = try? Data(contentsOf: url),
            let dataSet = String(bytes: data, encoding: .utf8) else {
                return TimestampedRSSIDataSet(timestampedRSSIs: [], clippedTimestampedRSSIs: [:])
        }
        
        var timestampedRSSIs = [TimestampedRSSI]()
        var clippedTimestampedRSSIs: [Int: [TimestampedRSSI]] = [-35: [], -60: []]
        let numberFormatter = NumberFormatter()
        let lines = dataSet.split { $0.isNewline }
        lines.forEach { line in
            let values = line.split(separator: ";").map { String($0) }
            
            guard values.count >= 3,
                let timeInterval = numberFormatter.number(from: values[0])?.intValue,
                let rssi = numberFormatter.number(from: values[1])?.intValue,
                let minus35DecibelsClippedRSSI = numberFormatter.number(from: values[2])?.intValue,
                let minus60DecibelsClippedRSSI = numberFormatter.number(from: values[3])?.intValue else {
                    return
            }
            
            let timestamp = Date(timeIntervalSince1970: TimeInterval(timeInterval))
            timestampedRSSIs.append(TimestampedRSSI(rssi: rssi, identifier: "", timestamp: timestamp))
            clippedTimestampedRSSIs[-35]?.append(TimestampedRSSI(rssi: minus35DecibelsClippedRSSI, identifier: "", timestamp: timestamp))
            clippedTimestampedRSSIs[-60]?.append(TimestampedRSSI(rssi: minus60DecibelsClippedRSSI, identifier: "", timestamp: timestamp))
        }
        
        return TimestampedRSSIDataSet(timestampedRSSIs: timestampedRSSIs, clippedTimestampedRSSIs: clippedTimestampedRSSIs)
    }
}

extension ProximityFilterTests {
    
    private struct TimestampedRSSIDataSet {
        
        let timestampedRSSIs: [TimestampedRSSI]
        
        let clippedTimestampedRSSIs: [Int: [TimestampedRSSI]]
    }
}

extension ProximityFilterTests {
    
    private struct ParameterizedData {
        
        let configuration: ProximityFilterConfiguration
        
        let timestampedRSSIs: [TimestampedRSSI]
        
        let expectedResult: Result<ProximityFilterOutput, ProximityFilterError>
        
        init(input: Input, expectedOutput: ExpectedOutput) {
            let inputTimestampedRSSIs = input.dataSet.timestampedRSSIs
            self.timestampedRSSIs = inputTimestampedRSSIs
            
            self.configuration = ProximityFilterConfiguration(durationThreshold: input.durationThreshold,
                                                              rssiThreshold: input.rssiThreshold,
                                                              riskThreshold: input.riskThreshold,
                                                              p0: input.p0,
                                                              a: input.a,
                                                              b: input.b)
            
            let expectedResult: Result<ProximityFilterOutput, ProximityFilterError>
            if let expectedError = expectedOutput.error {
                expectedResult = .failure(expectedError)
            } else {
                let outputTimestampedRSSIs = input.dataSet.clippedTimestampedRSSIs[input.rssiThreshold] ?? inputTimestampedRSSIs
                let areTimestampedRSSIsUpdated = inputTimestampedRSSIs.count != outputTimestampedRSSIs.count
                    || inputTimestampedRSSIs.sorted(by: { $0.timestamp < $1.timestamp }) != outputTimestampedRSSIs.sorted(by: { $0.timestamp < $1.timestamp })
                expectedResult = .success(ProximityFilterOutput(timestampedRSSIs: outputTimestampedRSSIs,
                                                                areTimestampedRSSIsUpdated: areTimestampedRSSIsUpdated,
                                                                windowRisks: expectedOutput.windowRisks,
                                                                meanPeak: expectedOutput.meanPeak,
                                                                peakCount: expectedOutput.peakCount,
                                                                intermediateRisk: expectedOutput.intermediateRisk,
                                                                risk: expectedOutput.risk,
                                                                durationInMinutes: expectedOutput.durationInMinutes,
                                                                riskDensity: expectedOutput.riskDensity))
            }
            self.expectedResult = expectedResult
        }
    }
}

extension ProximityFilterTests {
    
    private struct Input {
        
        let dataSet: TimestampedRSSIDataSet
        
        let durationThreshold: TimeInterval
        
        let rssiThreshold: Int
        
        let riskThreshold: Double
        
        let p0: Double
        
        let a: Double
        
        let b: Double
        
        init(dataSet: TimestampedRSSIDataSet,
             durationThreshold: TimeInterval = 2.0 * 60.0,
             rssiThreshold: Int = 0,
             riskThreshold: Double = 0.0,
             p0: Double = -66.0,
             a: Double = 4.34,
             b: Double = 0.2) {
            self.dataSet = dataSet
            self.durationThreshold = durationThreshold
            self.rssiThreshold = rssiThreshold
            self.riskThreshold = riskThreshold
            self.p0 = p0
            self.a = a
            self.b = b
        }
    }
}

extension ProximityFilterTests {
    
    private struct ExpectedOutput {
        
        let error: ProximityFilterError?
        
        let windowRisks: [Double]?
        
        let meanPeak: Double?
        
        let peakCount: Int?
        
        let intermediateRisk: Double?
        
        let risk: Double?
        
        let durationInMinutes: Double?
        
        let riskDensity: Int?
        
        init(error: ProximityFilterError? = nil,
             windowRisks: [Double]? = nil,
             meanPeak: Double? = nil,
             peakCount: Int? = nil,
             intermediateRisk: Double? = nil,
             risk: Double? = nil,
             durationInMinutes: Double? = nil,
             riskDensity: Int? = nil) {
            self.error = error
            self.windowRisks = windowRisks
            self.meanPeak = meanPeak
            self.peakCount = peakCount
            self.intermediateRisk = intermediateRisk
            self.risk = risk
            self.durationInMinutes = durationInMinutes
            self.riskDensity = riskDensity
        }
    }
}
