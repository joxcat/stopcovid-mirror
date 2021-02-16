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
    
    private var scannedPeripheralForPeripheralIdentifier: Cache<UUID, BluetoothPeripheral>
    
    private var bluetoothProximityPayloadForPeripheralIdentifier: Cache<UUID, BluetoothProximityPayload>
    
    private var connectionDateForPayloadIdentifier: Cache<ProximityPayloadIdentifier, Date>
    
    private var cacheExpirationTimer: Timer?
    
    private let dispatchQueue: DispatchQueue

    private let rssiCalibrator: BluetoothRSSICalibrator
    
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
        scannedPeripheralForPeripheralIdentifier = Cache<UUID, BluetoothPeripheral>(expirationDelay: settings.cacheExpirationDelay)
        bluetoothProximityPayloadForPeripheralIdentifier = Cache<UUID, BluetoothProximityPayload>(expirationDelay: settings.cacheExpirationDelay)
        rssiCalibrator = BluetoothRSSICalibrator(settings: settings)
        self.centralManager.delegate = self
        self.peripheralManager.delegate = self
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
    
    private func proximityInfo(for bluetoothPeripheral: BluetoothPeripheral,
                               from bluetoothProximityPayload: BluetoothProximityPayload) -> ProximityInfo? {
        guard let rawRSSI = bluetoothPeripheral.rssi,
              let calibratedRSSI = rssiCalibrator.calibrateRSSI(for: bluetoothPeripheral,
                                                                from: bluetoothProximityPayload) else { return nil }

        let metadata = BluetoothProximityMetadata(rawRSSI: rawRSSI,
                                                  calibratedRSSI: calibratedRSSI,
                                                  txPowerLevel: Int(bluetoothProximityPayload.txPowerLevel))
        return ProximityInfo(payload: bluetoothProximityPayload.payload,
                             timestamp: bluetoothPeripheral.timestamp,
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

    private func updateConnectionDate(for identifier: ProximityPayloadIdentifier) {
        connectionDateForPayloadIdentifier[identifier] = Date()
    }
}

extension BluetoothProximityNotification: BluetoothCentralManagerDelegate {
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol, stateDidChange state: ProximityNotificationState) {
        DispatchQueue.main.async {
            self.stateChangedHandler(state)
        }
    }
    
    func bluetoothCentralManager(_ centralManager: BluetoothCentralManagerProtocol,
                                 didScan peripheral: BluetoothPeripheral,
                                 bluetoothProximityPayload: BluetoothProximityPayload?) -> Bool {
        let peripheralIdentifier = peripheral.peripheralIdentifier
        scannedPeripheralForPeripheralIdentifier[peripheralIdentifier] = peripheral
        let bluetoothProximityPayload = bluetoothProximityPayload ?? bluetoothProximityPayloadForPeripheralIdentifier[peripheralIdentifier]
        
        if let bluetoothProximityPayload = bluetoothProximityPayload {
            guard let identifier = identifierFromProximityPayload?(bluetoothProximityPayload.payload) else { return false }
            
            let shouldConnect = connectionDateForPayloadIdentifier[identifier] == nil
            if shouldConnect {
                updateConnectionDate(for: identifier)
            }
            
            if let proximityInfo = self.proximityInfo(for: peripheral, from: bluetoothProximityPayload) {
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
            
            updateConnectionDate(for: identifier)
            
            if let proximityInfo = self.proximityInfo(for: peripheral, from: bluetoothProximityPayload) {
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

extension BluetoothProximityNotification: BluetoothPeripheralManagerDelegate {

    func bluetoothPeripheralManager(_ peripheralManager: BluetoothPeripheralManagerProtocol,
                                    didReceiveWriteFrom peripheral: BluetoothPeripheral,
                                    bluetoothProximityPayload: BluetoothProximityPayload) {
        if let proximityInfo = self.proximityInfo(for: peripheral, from: bluetoothProximityPayload) {
            proximityInfoUpdateHandler?(proximityInfo)
        }
    }
}
