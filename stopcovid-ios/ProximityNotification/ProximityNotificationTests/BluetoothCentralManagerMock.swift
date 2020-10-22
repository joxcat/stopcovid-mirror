/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/17 - for the TousAntiCovid project
 */

import Foundation
@testable import ProximityNotification

class BluetoothCentralManagerMock: BluetoothCentralManagerProtocol {
    
    weak var delegate: BluetoothCentralManagerDelegate?
    
    private(set) var state = ProximityNotificationState.off
    
    private let dispatchQueue: DispatchQueue
    
    private let startDelay = 0.2
    
    private let readCharacteristicDelay = 0.5
    
    init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider) {
        dispatchQueue.asyncAfter(deadline: .now() + startDelay) {
            self.state = .on
            self.delegate?.bluetoothCentralManager(self, stateDidChange: .on)
        }
    }
    
    func stop() {}
    
    func scheduleScan(peripheral: BluetoothScannedPeripheral,
                      payload: BluetoothProximityPayload,
                      isPayloadAdvertised: Bool,
                      after delay: TimeInterval) {
        dispatchQueue.asyncAfter(deadline: .now() + startDelay + delay) {
            let shouldAttemptConnection = self.delegate?.bluetoothCentralManager(self,
                                                                                 didScan: peripheral,
                                                                                 bluetoothProximityPayload: isPayloadAdvertised ? payload : nil)
            
            if shouldAttemptConnection == true && !isPayloadAdvertised {
                self.dispatchQueue.asyncAfter(deadline: .now() + self.readCharacteristicDelay) {
                    self.delegate?.bluetoothCentralManager(self,
                                                           didReadCharacteristicForPeripheralIdentifier: peripheral.peripheralIdentifier,
                                                           bluetoothProximityPayload: payload)
                }
            }
        }
    }
}
