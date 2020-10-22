/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import CoreBluetooth
import Foundation

class BluetoothPeripheralManager: NSObject, BluetoothPeripheralManagerProtocol {
    
    private let settings: BluetoothSettings
    
    private let dispatchQueue: DispatchQueue
    
    private var proximityPayloadProvider: ProximityPayloadProvider?
    
    private let logger: ProximityNotificationLogger
    
    private var peripheralManager: CBPeripheralManager?
    
    private let serviceUUID: CBUUID
    
    init(settings: BluetoothSettings,
         dispatchQueue: DispatchQueue,
         logger: ProximityNotificationLogger) {
        self.settings = settings
        self.dispatchQueue = dispatchQueue
        self.logger = logger
        serviceUUID = CBUUID(string: settings.serviceUniqueIdentifier)
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider) {
        logger.info(message: "start peripheral manager",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerStart.rawValue)
        self.proximityPayloadProvider = proximityPayloadProvider
        
        guard peripheralManager == nil else { return }
        
        let options = [CBPeripheralManagerOptionRestoreIdentifierKey: "proximitynotification-bluetoothperipheralmanager"]
        peripheralManager = CBPeripheralManager(delegate: self,
                                                queue: dispatchQueue,
                                                options: options)
    }
    
    func stop() {
        logger.info(message: "stop peripheral manager",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerStop.rawValue)
        
        stopPeripheralManager()
        peripheralManager?.delegate = nil
        peripheralManager = nil
    }
    
    private func stopPeripheralManager() {
        guard let peripheralManager = peripheralManager else { return }
        
        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }
        // Remove services when BT is off is an API misuse
        if peripheralManager.state == .poweredOn {
            peripheralManager.removeAllServices()
        }
    }
    
    private func startAdvertising() {
        logger.info(message: "start advertising",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerStartAdvertising.rawValue)
        
        let advertisementData = [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]]
        peripheralManager?.startAdvertising(advertisementData)
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logger.info(message: "peripheral manager did update state \(peripheral.state.rawValue)",
            source: ProximityNotificationEvent.bluetoothPeripheralManagerDidUpdateState.rawValue)
        
        stopPeripheralManager()
        
        switch peripheralManager?.state {
        case .poweredOn:
            let service = CBMutableService(type: serviceUUID,
                                           primary: true)
            let characteristic = CBMutableCharacteristic(type: CBUUID(string: settings.serviceCharacteristicUniqueIdentifier),
                                                         properties: [.read],
                                                         value: nil,
                                                         permissions: [.readable])
            service.characteristics = [characteristic]
            peripheral.add(service)
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        logger.info(message: "peripheral manager will restore state \(dict)",
            source: ProximityNotificationEvent.bluetoothPeripheralManagerWillRestoreState.rawValue)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        logger.info(message: "peripheral manager did add service",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidAddService.rawValue)
        
        guard error == nil else { return }
        
        startAdvertising()
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        logger.info(message: "peripheral manager did start advertising",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidStartAdvertising.rawValue)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logger.info(message: "peripheral manager did receive read",
                    source: ProximityNotificationEvent.bluetoothPeripheralManagerDidReceiveRead.rawValue)
        
        if let proximityPayload = proximityPayloadProvider?() {
            let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload,
                                                                      txPowerLevel: settings.txCompensationGain)
            request.value = bluetoothProximityPayload.data
            logger.info(message: "peripheral manager did respond read with success",
                        source: ProximityNotificationEvent.bluetoothPeripheralManagerDidRespondToReadWithSuccess.rawValue)
            peripheral.respond(to: request, withResult: .success)
        } else {
            logger.error(message: "peripheral manager did respond read with error",
                         source: ProximityNotificationEvent.bluetoothPeripheralManagerDidRespondToReadWithError.rawValue)
            peripheral.respond(to: request, withResult: .unlikelyError)
        }
    }
}
