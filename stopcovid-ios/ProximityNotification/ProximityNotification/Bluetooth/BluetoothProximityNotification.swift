/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/06 - for the TousAntiCovid project
 */

import Foundation

final class BluetoothProximityNotification: ProximityNotification {
    
    private let settings: BluetoothSettings
        
    private let centralManager: BluetoothCentralManagerProtocol
    
    private let peripheralManager: BluetoothPeripheralManagerProtocol
    
    private var proximityInfoUpdateHandler: ProximityInfoUpdateHandler?
    
    private var identifierFromProximityPayload: IdentifierFromProximityPayload?
    
    private var scannedPeripheralForPeripheralIdentifier: Cache<UUID, BluetoothScannedPeripheral>
    
    private var bluetoothProximityPayloadForPeripheralIdentifier: Cache<UUID, BluetoothProximityPayload>
    
    private var connectionDateForPayloadIdentifier: Cache<ProximityPayloadIdentifier, Date>
    
    private var cacheExpirationTimer: Timer?
    
    private let dispatchQueue: DispatchQueue
    
    let stateChangedHandler: StateChangedHandler
    
    var state: ProximityNotificationState {
        return centralManager.state
    }
    
    init(settings: BluetoothSettings,
         stateChangedHandler: @escaping StateChangedHandler,
         dispatchQueue: DispatchQueue,
         centralManager: BluetoothCentralManagerProtocol,
         peripheralManager: BluetoothPeripheralManagerProtocol) {
        self.settings = settings
        self.stateChangedHandler = stateChangedHandler
        self.dispatchQueue = dispatchQueue
        self.centralManager = centralManager
        self.peripheralManager = peripheralManager
        connectionDateForPayloadIdentifier = Cache(expirationDelay: settings.connectionTimeInterval)
        scannedPeripheralForPeripheralIdentifier = Cache<UUID, BluetoothScannedPeripheral>(expirationDelay: settings.cacheExpirationDelay)
        bluetoothProximityPayloadForPeripheralIdentifier = Cache<UUID, BluetoothProximityPayload>(expirationDelay: settings.cacheExpirationDelay)
        self.centralManager.delegate = self
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider,
               proximityInfoUpdateHandler: @escaping ProximityInfoUpdateHandler,
               identifierFromProximityPayload: @escaping IdentifierFromProximityPayload) {
        self.proximityInfoUpdateHandler = proximityInfoUpdateHandler
        self.identifierFromProximityPayload = identifierFromProximityPayload
        centralManager.start(proximityPayloadProvider: proximityPayloadProvider)
        peripheralManager.start(proximityPayloadProvider: proximityPayloadProvider)
        startCacheExpirationTimer()
    }
    
    func stop() {
        centralManager.stop()
        peripheralManager.stop()
        stopCacheExpirationTimer()
        scannedPeripheralForPeripheralIdentifier.removeAllValues()
        bluetoothProximityPayloadForPeripheralIdentifier.removeAllValues()
        connectionDateForPayloadIdentifier.removeAllValues()
    }
    
    private func proximityInfo(for bluetoothProximityPayload: BluetoothProximityPayload,
                               from scannedPeripheral: BluetoothScannedPeripheral) -> ProximityInfo? {
        guard let rssi = scannedPeripheral.rssi else {
            return nil
        }
        
        let calibratedRSSI = rssi - Int(bluetoothProximityPayload.txPowerLevel) - Int(settings.rxCompensationGain)
        let metadata = BluetoothProximityMetadata(rawRSSI: rssi,
                                                  calibratedRSSI: calibratedRSSI,
                                                  txPowerLevel: Int(bluetoothProximityPayload.txPowerLevel))
        return ProximityInfo(payload: bluetoothProximityPayload.payload,
                             timestamp: scannedPeripheral.timestamp,
                             metadata: metadata)
    }
    
    private func startCacheExpirationTimer() {
        stopCacheExpirationTimer()
        let timer = Timer(timeInterval: settings.cacheExpirationDelay / 5.0, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            
            self.scannedPeripheralForPeripheralIdentifier.removeExpiredValues()
            self.bluetoothProximityPayloadForPeripheralIdentifier.removeExpiredValues()
            self.connectionDateForPayloadIdentifier.removeExpiredValues()
        }
        
        cacheExpirationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func stopCacheExpirationTimer() {
        cacheExpirationTimer?.invalidate()
        cacheExpirationTimer = nil
    }
}

extension BluetoothProximityNotification: BluetoothCentralManagerDelegate {
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol, stateDidChange state: ProximityNotificationState) {
        DispatchQueue.main.async {
            self.stateChangedHandler(state)
        }
    }
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didScan peripheral: BluetoothScannedPeripheral,
                                 bluetoothProximityPayload: BluetoothProximityPayload?) -> Bool {
        let peripheralIdentifier = peripheral.peripheralIdentifier
        scannedPeripheralForPeripheralIdentifier[peripheralIdentifier] = peripheral
        let bluetoothProximityPayload = bluetoothProximityPayload ?? bluetoothProximityPayloadForPeripheralIdentifier[peripheralIdentifier]
        
        if let bluetoothProximityPayload = bluetoothProximityPayload {
            guard let identifier = identifierFromProximityPayload?(bluetoothProximityPayload.payload) else { return false }
            
            let shouldConnect = connectionDateForPayloadIdentifier[identifier] == nil
            if shouldConnect {
                connectionDateForPayloadIdentifier[identifier] = Date()
            }
            
            if let proximityInfo = self.proximityInfo(for: bluetoothProximityPayload, from: peripheral) {
                proximityInfoUpdateHandler?(proximityInfo)
            }
            
            return shouldConnect
        }
        
        return true
    }
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didReadCharacteristicForPeripheralIdentifier peripheralIdentifier: UUID,
                                 bluetoothProximityPayload: BluetoothProximityPayload) {
        bluetoothProximityPayloadForPeripheralIdentifier[peripheralIdentifier] = bluetoothProximityPayload
        
        if let peripheral = scannedPeripheralForPeripheralIdentifier[peripheralIdentifier],
            let identifier = identifierFromProximityPayload?(bluetoothProximityPayload.payload) {
            
            connectionDateForPayloadIdentifier[identifier] = Date()
            
            if let proximityInfo = self.proximityInfo(for: bluetoothProximityPayload, from: peripheral) {
                proximityInfoUpdateHandler?(proximityInfo)
            }
        }
    }
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didNotFindServiceForPeripheralIdentifier peripheralIdentifier: UUID) {
        scannedPeripheralForPeripheralIdentifier.removeValue(forKey: peripheralIdentifier)
        bluetoothProximityPayloadForPeripheralIdentifier.removeValue(forKey: peripheralIdentifier)
    }
}
