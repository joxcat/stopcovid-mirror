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

class BluetoothPeripheralManagerMock: BluetoothPeripheralManagerProtocol {

    weak var delegate: BluetoothPeripheralManagerDelegate?

    private let dispatchQueue: DispatchQueue

    init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider) {}
    
    func stop() {}

    func scheduleIncomingWriteRequest(from bluetoothPeripheral: BluetoothPeripheral,
                                      payload: BluetoothProximityPayload,
                                      after delay: TimeInterval) {
        dispatchQueue.asyncAfter(deadline: .now() + delay) {
            self.delegate?.bluetoothPeripheralManager(self,
                                                      didReceiveWriteFrom: bluetoothPeripheral,
                                                      bluetoothProximityPayload: payload)
        }
    }
}
