// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBBluetooth.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 30/04/2020 - for the STOP-COVID project.
//

import UIKit

protocol RBBluetooth {

    func start(helloMessageCreationHandler: @escaping () -> Data,
               ebidExtractionHandler: @escaping (_ data: Data) -> Data,
               didReceiveProximity: @escaping (_ proximity: RBReceivedProximity) -> ())
    func stop()
    
}
