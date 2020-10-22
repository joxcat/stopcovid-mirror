// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  RBBluetooth.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 30/04/2020 - for the TousAntiCovid project.
//

import UIKit

public protocol RBBluetooth {

    func start(helloMessageCreationHandler: @escaping (_ completion: @escaping (_ data: Data?) -> ()) -> (),
               ebidExtractionHandler: @escaping (_ data: Data) -> Data,
               didReceiveProximity: @escaping (_ proximity: RBReceivedProximity) -> ())
    func stop()
    
}
