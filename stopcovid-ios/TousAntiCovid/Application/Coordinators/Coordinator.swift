// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Coordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

protocol Coordinator: class {
    
    var parent: Coordinator? { get set }
    var childCoordinators: [Coordinator] { get set }
    
    func addChild(coordinator: Coordinator)
    func removeChild(coordinator: Coordinator)
    func didDeinit()
    
}

// MARK: - Children management -
extension Coordinator {
    
    func addChild(coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChild(coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
    
    func didDeinit() {
        parent?.removeChild(coordinator: self)
    }

}
