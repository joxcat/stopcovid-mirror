// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BluetoothManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 30/04/2020 - for the STOP-COVID project.
//

import UIKit
import ProximityNotification
import RobertSDK
import ServerSDK

final class BluetoothManager: RBBluetooth {
    
    private var service: ProximityNotificationService?
    
    func start(helloMessageCreationHandler: @escaping (_ completion: @escaping (_ data: Data?) -> ()) -> (),
               ebidExtractionHandler: @escaping (_ data: Data) -> Data,
               didReceiveProximity: @escaping (_ proximity: RBReceivedProximity) -> ()) {
        guard let serviceUuid = ParametersManager.shared.bleServiceUuid, let characteristicUuid = ParametersManager.shared.bleCharacteristicUuid else { return }
        let deviceParams: DeviceParameters? = ParametersManager.shared.getDeviceParametersFor(model: UIDevice.current.modelName)
        let bleSettings = BluetoothSettings(serviceUniqueIdentifier: serviceUuid,
                                            serviceCharacteristicUniqueIdentifier: characteristicUuid,
                                            txCompensationGain: Int8(deviceParams?.txFactor ?? 0.0),
                                            rxCompensationGain: Int8(deviceParams?.rxFactor ?? 0.0))
        let stateChangedHandler: StateChangedHandler = { _ in }
        service = ProximityNotificationService(settings: ProximityNotificationSettings(bluetoothSettings: bleSettings),
                                               stateChangedHandler: stateChangedHandler)
        
        let proximityPayloadProvider: ProximityPayloadProvider = { () -> ProximityPayload? in
            var data: Data?
            let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
            helloMessageCreationHandler { helloMessageData in
                data = helloMessageData
                semaphore.signal()
            }
            semaphore.wait()
            return ProximityPayload(data: data ?? Data())
        }
        let identifierFromProximityPayload: IdentifierFromProximityPayload = { proximityPayload -> Data? in
            return ebidExtractionHandler(proximityPayload.data)
        }
        let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { proximity in
            DispatchQueue.main.async {
                guard let metadata = proximity.metadata as? BluetoothProximityMetadata else { return }
                let proximity: RBReceivedProximity = RBReceivedProximity(data: proximity.payload.data,
                                                                         timeCollectedOnDevice: proximity.timestamp.timeIntervalSince1900,
                                                                         rssiRaw: metadata.rawRSSI,
                                                                         rssiCalibrated: metadata.calibratedRSSI,
                                                                         tx: metadata.txPowerLevel)
                didReceiveProximity(proximity)
            }
        }
        service?.start(proximityPayloadProvider: proximityPayloadProvider,
                      proximityInfoUpdateHandler: proximityInfoUpdateHandler,
                      identifierFromProximityPayload: identifierFromProximityPayload)
    }
    
    func stop() {
        service?.stop()
        service = nil
    }
    
}
