// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  MaintenanceSupportingCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 21/05/2020 - for the TousAntiCovid project.
//


import UIKit

protocol MaintenanceSupportingCoordinator {

    func showMaintenance(info: MaintenanceInfo)
    func hideMaintenance()
    
}
