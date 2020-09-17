//
//  FilteringManager.swift
//  StopCovid
//
//  Created by Lunabee Studio / Date - 18/06/2020 - for the STOP-COVID project.
//

import Foundation
import ProximityNotification
import RobertSDK
import ServerSDK

final class FilteringManager: RBFiltering {
    
    func filter(proximities: [RBLocalProximity]) throws -> [RBLocalProximity] {
        guard let filterMode = ProximityFilterMode.from(modeString: ParametersManager.shared.bleFilteringMode) else {
            throw NSError.localizedError(message: "Missing or malformed filtering mode", code: 0)
        }
        guard let configJSON = ParametersManager.shared.bleFilteringConfig else {
            throw NSError.localizedError(message: "Missing filtering config", code: 0)
        }
        
        do {
            let configuration: ProximityFilterConfiguration = try proximityConfiguration(configJSON: configJSON)
            let filterService: ProximityFilter = ProximityFilter(configuration: configuration)
            let groupedByEBID: [String: [RBLocalProximity]] = Dictionary(grouping: proximities) { $0.ebid }
            var filteredHelloMessage: [RBLocalProximity] = []
            
            groupedByEBID.forEach { ebid, list in
                guard let firstHelloMessage = list.first else { return }
                
                let epochStartTime: Int = (firstHelloMessage.timeCollectedOnDevice / RBConstants.epochDurationInSeconds) * RBConstants.epochDurationInSeconds
                let epochStartDate: Date = Date(timeIntervalSince1900: epochStartTime)
                
                let timestampedRssiList: [TimestampedRSSI] = list.map {
                    TimestampedRSSI(rssi: $0.rssiCalibrated, identifier: $0.hashValue, timestamp: Date(timeIntervalSince1900: $0.timeCollectedOnDevice))
                }
                
                let filterOutput: Result<ProximityFilterOutput, ProximityFilterError> = filterService.filterRSSIs(timestampedRssiList,
                                                                                                                  from:epochStartDate,
                                                                                                                  withEpochDuration: TimeInterval(RBConstants.epochDurationInSeconds),
                                                                                                                  mode:filterMode)
                switch filterOutput {
                    case let .success(proximityFilterOutput):
                        if proximityFilterOutput.areTimestampedRSSIsUpdated {
                            proximityFilterOutput.timestampedRSSIs.forEach { timeStampedRssi in
                                if let matchingLocalProximity = list.first(where: { $0.hashValue == timeStampedRssi.identifier as? Int }) {
                                    var localProximity = matchingLocalProximity
                                    localProximity.rssiCalibrated = timeStampedRssi.rssi
                                    filteredHelloMessage.append(localProximity)
                                }
                            }
                        } else {
                            filteredHelloMessage.append(contentsOf: list)
                        }
                    case .failure:
                        break
                }
            }
            return filteredHelloMessage
        } catch {
            throw error
        }
    }
    
    private func proximityConfiguration(configJSON: String) throws -> ProximityFilterConfiguration {
        guard let data = configJSON.data(using: .utf8) else { return ProximityFilterConfiguration() }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return ProximityFilterConfiguration() }
            return ProximityFilterConfiguration(durationThreshold: Double(json["durationThreshold"] as? Double ?? 5.0 * 60.0),
                                                rssiThreshold: json["rssiThreshold"] as? Int ?? 0,
                                                riskThreshold: json["riskThreshold"] as? Double ?? 0.2,
                                                deltas: json["deltas"] as? [Double] ?? [39.0, 27.0, 23.0, 21.0, 20.0, 19.0, 18.0, 17.0, 16.0, 15.0],
                                                p0: json["p0"] as? Double ?? -66.0,
                                                a: json["a"] as? Double ?? 10.0 / log(10.0),
                                                b: json["b"] as? Double ?? 0.1,
                                                timeWindow: json["timeWindow"] as? Double ?? 120.0,
                                                timeOverlap: json["timeOverlap"] as? Double ?? 60.0)
        } catch {
            let error: Error = NSError.localizedError(message: error.localizedDescription, code: 0)
            throw error
        }
    }
    
}

private extension ProximityFilterMode {
    
    static func from(modeString: String?) -> ProximityFilterMode? {
        guard let modeString = modeString else { return nil }
        switch modeString {
            case "RISKS":
                return .risks
            case "FULL":
                return .full
            case "MEDIUM":
                return .medium
            default:
                return nil
        }
    }
    
}
