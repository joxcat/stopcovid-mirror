// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OrientationManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol OrientationChangesObserver: class {
    
    func orientationActivationStateDidChange()
    
}

final class OrientationObserverWrapper: NSObject {
    
    weak var observer: OrientationChangesObserver?
    
    init(observer: OrientationChangesObserver) {
        self.observer = observer
    }
    
}

final class OrientationManager {

    static let shared: OrientationManager = OrientationManager()
    var isPowerSaveModeOrientation: Bool { ![.faceUp, .portrait].contains(UIDevice.current.orientation) }
    
    private var observers: [OrientationObserverWrapper] = []
    private var wasPowerSaveModeOrientation: Bool = false
    
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveOrientationChangeNotification), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func didReceiveOrientationChangeNotification() {
        guard UIDevice.current.orientation != .unknown else { return }
        if isPowerSaveModeOrientation != wasPowerSaveModeOrientation {
            notifyObservers()
            wasPowerSaveModeOrientation = isPowerSaveModeOrientation
        }
    }
    
}

extension OrientationManager {
    
    func addObserver(_ observer: OrientationChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(OrientationObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: OrientationChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: OrientationChangesObserver) -> OrientationObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.orientationActivationStateDidChange() }
    }
    
}
