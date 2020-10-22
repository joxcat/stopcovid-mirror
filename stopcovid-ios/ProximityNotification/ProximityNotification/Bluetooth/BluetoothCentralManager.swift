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

class BluetoothCentralManager: NSObject, BluetoothCentralManagerProtocol {
    
    weak var delegate: BluetoothCentralManagerDelegate?
    
    private let settings: BluetoothSettings
    
    private let dispatchQueue: DispatchQueue
    
    private var proximityPayloadProvider: ProximityPayloadProvider?
    
    private let logger: ProximityNotificationLogger
    
    private var centralManager: CBCentralManager?
    
    private var connectingPeripherals = Set<CBPeripheral>()
    
    private var connectionTimeoutTimersForPeripheralIdentifiers = [UUID: Timer]()
    
    private var peripheralsToWriteValue = Set<CBPeripheral>()
    
    private var restoredPeripherals: [CBPeripheral]?
    
    private let serviceUUID: CBUUID
    
    private let characteristicUUID: CBUUID
    
    init(settings: BluetoothSettings,
         dispatchQueue: DispatchQueue,
         logger: ProximityNotificationLogger) {
        self.settings = settings
        self.dispatchQueue = dispatchQueue
        self.logger = logger
        serviceUUID = CBUUID(string: settings.serviceUniqueIdentifier)
        characteristicUUID = CBUUID(string: settings.serviceCharacteristicUniqueIdentifier)
    }
    
    var state: ProximityNotificationState {
        return centralManager?.state.toProximityNotificationState() ?? .off
    }
    
    func start(proximityPayloadProvider: @escaping ProximityPayloadProvider) {
        logger.info(message: "start central manager",
                    source: ProximityNotificationEvent.bluetoothCentralManagerStart.rawValue)
        self.proximityPayloadProvider = proximityPayloadProvider
        
        guard centralManager == nil else { return }
        
        let options = [CBCentralManagerOptionRestoreIdentifierKey: "proximitynotification-bluetoothcentralmanager"]
        centralManager = CBCentralManager(delegate: self,
                                          queue: dispatchQueue,
                                          options: options)
    }
    
    func stop() {
        logger.info(message: "stop central manager",
                    source: ProximityNotificationEvent.bluetoothCentralManagerStop.rawValue)
        
        stopCentralManager()
        
        centralManager?.delegate = nil
        centralManager = nil
        
        dispatchQueue.sync {
            self.cleanPeripherals()
        }
    }
    
    private func stopCentralManager() {
        guard let centralManager = centralManager else { return }
        
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    private func scanForPeripherals() {
        logger.info(message: "scan for peripherals",
                    source: ProximityNotificationEvent.bluetoothCentralManagerScanForPeripherals.rawValue)
        
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)]
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: options)
    }
    
    private func connectIfNeeded(_ peripheral: CBPeripheral) {
        guard peripheral.state != .connected else {
            logger.info(message: "peripheral \(peripheral) already connected to central manager",
                source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralAlreadyConnected.rawValue)
            return
        }
        
        if peripheral.state != .connecting {
            logger.info(message: "central manager connecting to peripheral \(peripheral)",
                source: ProximityNotificationEvent.bluetoothCentralManagerConnectingToPeripheral.rawValue)
            connectingPeripherals.insert(peripheral)
            centralManager?.connect(peripheral, options: nil)
            // Attempts to connect to a peripheral don’t time out, so manage it manually
            launchConnectionTimeoutTimer(for: peripheral)
        }
    }
    
    private func launchConnectionTimeoutTimer(for peripheral: CBPeripheral) {
        // Invalidate the previous one before
        connectionTimeoutTimersForPeripheralIdentifiers[peripheral.identifier]?.invalidate()
        
        // Must be lower than 10 seconds
        let timer = Timer(timeInterval: 5, repeats: false) { [weak self] _ in
            guard let `self` = self else { return }
            
            self.dispatchQueue.async {
                if peripheral.state != .connected {
                    self.logger.error(message: "central manager connection timeout to peripheral \(peripheral)",
                        source: ProximityNotificationEvent.bluetoothCentralManagerConnectionTimeoutToPeripheral.rawValue)
                    self.disconnectPeripheral(peripheral)
                }
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
        connectionTimeoutTimersForPeripheralIdentifiers[peripheral.identifier] = timer
    }
    
    private func discoverServices(of peripheral: CBPeripheral) {
        peripheral.delegate = self
        if peripheral.services == nil {
            peripheral.discoverServices([serviceUUID])
            logger.info(message: "peripheral \(peripheral) discovering services",
                source: ProximityNotificationEvent.bluetoothCentralManagerStartDiscoveringPeripheralServices.rawValue)
        } else {
            logger.info(message: "peripheral \(peripheral) has already discovered services",
                source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralServicesAlreadyDiscovered.rawValue)
            discoverCharacteristics(of: peripheral)
        }
    }
    
    private func discoverCharacteristics(of peripheral: CBPeripheral) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            logger.error(message: "service not found for peripheral \(peripheral)",
                source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralServiceNotFound.rawValue)
            delegate?.bluetoothCentralManager(self, didNotFindServiceForPeripheralIdentifier: peripheral.identifier)
            disconnectPeripheral(peripheral)
            return
        }
        
        if service.characteristics == nil {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
            logger.info(message: "peripheral \(peripheral) discovering characteristics",
                source: ProximityNotificationEvent.bluetoothCentralManagerStartDiscoveringServiceCharacteristics.rawValue)
        } else {
            logger.info(message: "peripheral \(peripheral) has already discovered characteristics",
                source: ProximityNotificationEvent.bluetoothCentralManagerServiceCharacteristicsAlreadyDiscovered.rawValue)
            exchangeValue(for: peripheral, on: service)
        }
    }
    
    private func exchangeValue(for peripheral: CBPeripheral, on service: CBService) {
        guard service.uuid == serviceUUID,
            let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
                logger.error(message: "service and characteristic not found for peripheral \(peripheral)",
                    source: ProximityNotificationEvent.bluetoothCentralManagerServiceCharacteristicNotFound.rawValue)
                disconnectPeripheral(peripheral)
                return
        }
        
        if peripheralsToWriteValue.contains(peripheral) {
            if let proximityPayload = proximityPayloadProvider?() {
                logger.info(message: "peripheral \(peripheral) write value",
                    source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralWriteValue.rawValue)
                let bluetoothProximityPayload = BluetoothProximityPayload(payload: proximityPayload,
                                                                          txPowerLevel: settings.txCompensationGain)
                peripheral.writeValue(bluetoothProximityPayload.data, for: characteristic, type: .withResponse)
            }
        } else {
            logger.info(message: "peripheral \(peripheral) read value",
                source: ProximityNotificationEvent.bluetoothCentralManagerPeripheralReadValue.rawValue)
            peripheral.readValue(for: characteristic)
        }
    }
    
    private func cleanPeripheral(_ peripheral: CBPeripheral) {
        logger.debug(message: "clean peripheral \(peripheral)",
            source: ProximityNotificationEvent.bluetoothCentralManagerCleanPeripheral.rawValue)
        
        peripheral.delegate = nil
        connectionTimeoutTimersForPeripheralIdentifiers[peripheral.identifier]?.invalidate()
        connectionTimeoutTimersForPeripheralIdentifiers[peripheral.identifier] = nil
        connectingPeripherals.remove(peripheral)
        peripheralsToWriteValue.remove(peripheral)
    }
    
    private func cleanPeripherals() {
        logger.debug(message: "clean peripherals (\(connectingPeripherals.count))",
            source: ProximityNotificationEvent.bluetoothCentralManagerCleanAllPeripherals.rawValue)
        
        connectingPeripherals.forEach({ $0.delegate = nil })
        connectionTimeoutTimersForPeripheralIdentifiers.values.forEach({ $0.invalidate() })
        connectionTimeoutTimersForPeripheralIdentifiers.removeAll()
        connectingPeripherals.removeAll()
        peripheralsToWriteValue.removeAll()
    }
    
    private func disconnectPeripheral(_ peripheral: CBPeripheral) {
        logger.debug(message: "disconnect peripheral \(peripheral)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDisconnectPeripheral.rawValue)
        
        if peripheral.state == .connecting || peripheral.state == .connected {
            logger.info(message: "central manager cancelling connection to peripheral \(peripheral)",
                source: ProximityNotificationEvent.bluetoothCentralManagerCancellingConnectionToPeripheral.rawValue)
            centralManager?.cancelPeripheralConnection(peripheral)
            peripheral.delegate = nil
        } else {
            cleanPeripheral(peripheral)
        }
    }
    
    private func disconnectPeripherals() {
        connectingPeripherals.forEach({ disconnectPeripheral($0) })
    }
}

extension BluetoothCentralManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info(message: "central manager did update state \(central.state.rawValue)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidUpdateState.rawValue)
        
        disconnectPeripherals()
        stopCentralManager()
        
        switch central.state {
        case .poweredOn:
            restoredPeripherals?.forEach({ disconnectPeripheral($0) })
            restoredPeripherals?.removeAll()
            scanForPeripherals()
        default:
            break
        }
        
        delegate?.bluetoothCentralManager(self, stateDidChange: central.state.toProximityNotificationState())
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        logger.info(message: "central manager will restore state \(dict)",
            source: ProximityNotificationEvent.bluetoothCentralManagerWillRestoreState.rawValue)
        
        restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        logger.info(message: "central manager did discover peripheral \(peripheral)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidDiscoverPeripheral.rawValue)
        
        var bluetoothProximityPayload: BluetoothProximityPayload?
        if let advertisementDataServiceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
            let serviceData = advertisementDataServiceData[serviceUUID] {
            bluetoothProximityPayload = BluetoothProximityPayload(data: serviceData)
        }
        
        // According to documentation in CBCentralManager.h,
        // value of 127 is reserved and indicates the RSSI was not available.
        let rssi = RSSI.intValue != Int8.max ? RSSI.intValue : nil
        let scannedPeripheral = BluetoothScannedPeripheral(peripheralIdentifier: peripheral.identifier,
                                                           timestamp: Date(),
                                                           rssi: rssi)
        let shouldAttemptConnection = delegate?.bluetoothCentralManager(self,
                                                                        didScan: scannedPeripheral,
                                                                        bluetoothProximityPayload: bluetoothProximityPayload) ?? false
        
        if shouldAttemptConnection {
            // Android found with the data, connect to the peripheral and write own payload
            // otherwise it's an iPhone, connect to the peripheral to read remote payload
            if bluetoothProximityPayload != nil {
                peripheralsToWriteValue.insert(peripheral)
            }
            connectIfNeeded(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info(message: "central manager did connect to peripheral \(peripheral)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidConnectToPeripheral.rawValue)
        
        // Invalidate the current timeout timer
        connectionTimeoutTimersForPeripheralIdentifiers[peripheral.identifier]?.invalidate()
        connectionTimeoutTimersForPeripheralIdentifiers[peripheral.identifier] = nil
        
        discoverServices(of: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error(message: "central manager did fail to connect to peripheral \(peripheral)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidFailToConnectToPeripheral.rawValue)
        
        cleanPeripheral(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info(message: "central manager did disconnect from peripheral \(peripheral)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidDisconnectFromPeripheral.rawValue)
        
        cleanPeripheral(peripheral)
    }
}

extension BluetoothCentralManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.info(message: "peripheral \(peripheral) did discover services",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidDiscoverPeripheralServices.rawValue)
        
        discoverCharacteristics(of: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info(message: "peripheral \(peripheral) did discover characteristics",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidDiscoverPeripheralCharacteristics.rawValue)
        
        exchangeValue(for: peripheral, on: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.info(message: "peripheral \(peripheral) did update value for characteristic",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidUpdatePeripheralValueForCharacteristic.rawValue)
        
        if let readValue = characteristic.value,
            let bluetoothProximityPayload = BluetoothProximityPayload(data: readValue) {
            logger.info(message: "peripheral \(peripheral) did read characteristic",
                source: ProximityNotificationEvent.bluetoothCentralManagerDidReadPeripheralCharacteristic.rawValue)
            delegate?.bluetoothCentralManager(self,
                                              didReadCharacteristicForPeripheralIdentifier: peripheral.identifier,
                                              bluetoothProximityPayload: bluetoothProximityPayload)
        }
        
        disconnectPeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.info(message: "peripheral \(peripheral) did write value for characteristic",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidWriteValueToPeripheralForCharacteristic.rawValue)
        
        disconnectPeripheral(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        logger.info(message: "peripheral \(peripheral) did modify services \(invalidatedServices)",
            source: ProximityNotificationEvent.bluetoothCentralManagerDidModifyServices.rawValue)
        
        if invalidatedServices.contains(where: { $0.uuid == serviceUUID }) {
            delegate?.bluetoothCentralManager(self, didNotFindServiceForPeripheralIdentifier: peripheral.identifier)
            disconnectPeripheral(peripheral)
        }
    }
}
