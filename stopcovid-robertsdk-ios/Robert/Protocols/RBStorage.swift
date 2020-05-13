// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBStorage.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 27/04/2020 - for the STOP-COVID project.
//

import Foundation

protocol RBStorage {

    func start()
    func stop()
    
    // MARK: - Epoch -
    func save(epochs: [RBEpoch])
    func getCurrentEpoch() -> RBEpoch?
    func getEpoch(for id: Int) -> RBEpoch?
    func getLastEpoch() -> RBEpoch?
    
    // MARK: - TimeStart -
    func save(timeStart: Int) throws
    func getTimeStart() throws -> Int
    
    // MARK: - Key -
    func save(key: Data)
    func getKey() -> Data?
    func isKeyStored() -> Bool
    
    // MARK: - Proximity -
    func save(proximityActivated: Bool)
    func isProximityActivated() -> Bool
    
    // MARK: - Local Proximity -
    func save(localProximity: RBLocalProximity)
    func getLocalProximityList() -> [RBLocalProximity]
    
    // MARK: - Status: isAtRisk -
    func save(isAtRisk: Bool?)
    func isAtRisk() -> Bool?
    
    // MARK: - Status: last exposure time frame -
    func save(lastExposureTimeFrame: Int?)
    func lastExposureTimeFrame() -> Int?
    
    // MARK: - Status: last status received date -
    func saveLastStatusReceivedDate(_ date: Date?)
    func lastStatusReceivedDate() -> Date?
    
    // MARK: - Status: Is sick -
    func save(isSick: Bool)
    func isSick() -> Bool
    
    // MARK: - Data cleraing -
    func clearLocalEpochs()
    func clearLocalProximityList()
    func clearAll(includingDBKey: Bool)
    
}
