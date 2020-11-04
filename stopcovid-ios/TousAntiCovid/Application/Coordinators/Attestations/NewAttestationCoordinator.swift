// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  NewAttestationCoordinator.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 29/10/2020 - for the TousAntiCovid project.
//

import UIKit

final class NewAttestationCoordinator: Coordinator {

    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var navigationController: UINavigationController?
    private weak var presentingController: UIViewController?
    
    init(presentingController: UIViewController?, parent: Coordinator) {
        self.presentingController = presentingController
        self.parent = parent
        start()
    }
    
    private func start() {
        let navigationController: CVNavigationController = CVNavigationController(rootViewController: NewAttestationViewController(didTouchSelectFieldItem: { [weak self] items, selectedItem, didSelectItem in
            self?.showFieldItemPicker(items: items, selectedItem: selectedItem, didSelectFieldItem: didSelectItem)
        }) { [weak self] in
            self?.didDeinit()
        })
        self.navigationController = navigationController
        presentingController?.present(navigationController, animated: true)
    }
    
    private func showFieldItemPicker(items: [AttestationFormFieldItem], selectedItem: AttestationFormFieldItem?, didSelectFieldItem: @escaping (_ fieldValue: AttestationFormFieldItem) -> ()) {
        let controller: AttestationFieldValueChoiceViewController = AttestationFieldValueChoiceViewController(items: items, selectedItem: selectedItem, didSelectFieldItem: { [weak self] selectedItem in
            self?.navigationController?.popToRootViewController(animated: true)
            didSelectFieldItem(selectedItem)
        })
        navigationController?.pushViewController(controller, animated: true)
    }
    
}
