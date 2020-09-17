// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BluetoothStateManager.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 30/04/2020 - for the STOP-COVID project.
//

import UIKit
import CoreBluetooth

protocol BluetoothStateObserver: class {
    
    func bluetoothStateDidUpdate()
    
}

final class BluetoothStateObserverWrapper: NSObject {
    
    weak var observer: BluetoothStateObserver?
    
    init(observer: BluetoothStateObserver) {
        self.observer = observer
    }
    
}

final class BluetoothStateManager: NSObject {
    
    static let shared: BluetoothStateManager = BluetoothStateManager()
    
    var isAuthorized: Bool {
        if #available(iOS 13.0, *) {
            guard let peripheralManager = peripheralManager else { return false }
            return peripheralManager.state != .unauthorized || Constant.isSimulator
        } else {
            return CBPeripheralManager.authorizationStatus() == .authorized || Constant.isSimulator
        }
    }
    var isActivated: Bool { peripheralManager?.state == .poweredOn || Constant.isSimulator }
    var isUnknown: Bool { peripheralManager?.state == .unknown }
    private var peripheralManager: CBPeripheralManager?
    private var observers: [BluetoothStateObserverWrapper] = []
    private var authorizationHandler: (() -> ())?
    
    func requestAuthorization(_ completion: @escaping () -> ()) {
        authorizationHandler = completion
        start()
    }
    
    func start() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
}

extension BluetoothStateManager: CBPeripheralManagerDelegate {
 
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if let handler = authorizationHandler {
            handler()
            authorizationHandler = nil
        }
        notifyObservers()
    }
    
}

extension BluetoothStateManager {
    
    func addObserver(_ observer: BluetoothStateObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(BluetoothStateObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: BluetoothStateObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: BluetoothStateObserver) -> BluetoothStateObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.bluetoothStateDidUpdate() }
    }
    
}
