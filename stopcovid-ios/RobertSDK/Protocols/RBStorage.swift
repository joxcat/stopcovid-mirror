// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBStorage.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the TousAntiCovid project.
//

import Foundation

public protocol RBStorage {

    func start()
    func stop()
    
    // MARK: - Epoch -
    func save(epochs: [RBEpoch])
    func getCurrentEpoch(defaultingToLast: Bool) -> RBEpoch?
    func getEpoch(for id: Int) -> RBEpoch?
    func getLastEpoch() -> RBEpoch?
    func epochsCount() -> Int
    
    // MARK: - TimeStart -
    func save(timeStart: Int) throws
    func getTimeStart() throws -> Int
    
    // MARK: - Keys -
    func save(ka: Data)
    func getKa() -> Data?
    func save(kea: Data)
    func getKea() -> Data?
    func areKeysStored() -> Bool
    
    // MARK: - Proximity -
    func save(proximityActivated: Bool)
    func isProximityActivated() -> Bool
    
    // MARK: - Local Proximity -
    func save(localProximity: RBLocalProximity) -> Bool
    func getLocalProximityList() -> [RBLocalProximity]
    func getLocalProximityList(from: Date, to: Date) -> [RBLocalProximity]
    func clearProximityList(before date: Date)
    
    // MARK: - Status: last exposure time frame -
    func save(lastExposureTimeFrame: Int?)
    func lastExposureTimeFrame() -> Int?

    // MARK: - Status: last status request date -
    func saveLastStatusRequestDate(_ date: Date?)
    func lastStatusRequestDate() -> Date?

    // MARK: - Status: last status received date -
    func saveLastStatusReceivedDate(_ date: Date?)
    func lastStatusReceivedDate() -> Date?
    
    // MARK: - Status: last status error date -
    func saveLastStatusErrorDate(_ date: Date?)
    func lastStatusErrorDate() -> Date?
    
    // MARK: - Status: last risk received date -
    func saveLastRiskReceivedDate(_ date: Date?)
    func lastRiskReceivedDate() -> Date?
    
    // MARK: - Status: Is sick -
    func save(isSick: Bool)
    func isSick() -> Bool
    
    // MARK: - Push token -
    func save(pushToken: String?)
    func pushToken() -> String?
    
    // MARK: - Report dates -
    func saveReportDate(_ date: Date?)
    func reportDate() -> Date?
    func saveReportDataOriginDate(_ date: Date?)
    func reportDataOriginDate() -> Date?
    func saveReportSymptomsStartDate(_ date: Date?)
    func reportSymptomsStartDate() -> Date?
    func saveReportPositiveTestDate(_ date: Date?)
    func reportPositiveTestDate() -> Date?
    
    // MARK: - Report token -
    func saveReportToken(_ token: String?)
    func reportToken() -> String?
    
    // MARK: - Declaration token -
    func saveDeclarationToken(_ token: String?)
    func declarationToken() -> String?
    
    // MARK: - Status: Current risk level -
    func saveCurrentStatusRiskLevel(_ statusRiskLevelInfo: RBStatusRiskLevelInfo?)
    func currentStatusRiskLevel() -> RBStatusRiskLevelInfo?
    
    // MARK: - Status: Last Robert risk level -
    func saveLastRobertStatusRiskLevel(_ statusRiskLevelInfo: RBStatusRiskLevelInfo?)
    func lastRobertStatusRiskLevel() -> RBStatusRiskLevelInfo?
    
    // MARK: - Status: Last Warning risk level -
    func saveLastWarningStatusRiskLevel(_ statusRiskLevelInfo: RBStatusRiskLevelInfo?)
    func lastWarningStatusRiskLevel() -> RBStatusRiskLevelInfo?
    
    // MARK: - Data cleraing -
    func clearLocalEpochs()
    func clearLocalProximityList()
    func clearAll(includingDBKey: Bool)

}
