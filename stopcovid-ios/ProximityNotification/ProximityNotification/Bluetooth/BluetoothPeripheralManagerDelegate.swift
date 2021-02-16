/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/11/10 - for the TousAntiCovid project
 */

import Foundation

protocol BluetoothPeripheralManagerDelegate: class {

    func bluetoothPeripheralManager(_ peripheralManager: BluetoothPeripheralManagerProtocol, didReceiveWriteFrom peripheral: BluetoothPeripheral, bluetoothProximityPayload: BluetoothProximityPayload)
}
