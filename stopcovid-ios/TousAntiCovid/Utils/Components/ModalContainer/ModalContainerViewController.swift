// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  ModalContainerViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class ModalContainerViewController: UIViewController {
    
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var containerView: UIView!
    
    @IBOutlet private var containerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private var containerViewTopToHeaderConstraint: NSLayoutConstraint!
    
    private var embeddedController: UIViewController?
    private var isFullScreen: Bool = false
    
    class func controller(_ embeddedController: UIViewController, isFullScreen: Bool = false) -> UIViewController {
        let containerController: ModalContainerViewController = StoryboardScene.ModalContainer.modalContainerViewController.instantiate()
        containerController.embeddedController = embeddedController
        containerController.isFullScreen = isFullScreen
        return containerController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.background.color
        setupEmbeddedController()
    }
    
    private func setupEmbeddedController() {
        guard let controller = embeddedController else { return }
        addChildViewController(controller, containerView: containerView)
        if isFullScreen {
            headerView.backgroundColor = .clear
            containerViewTopConstraint.isActive = true
            containerViewTopToHeaderConstraint.isActive = false
        }
    }

}

extension UIViewController {
    
    var modalContainerController: ModalContainerViewController? {
        var parentController: UIViewController? = self
        while let controller = parentController?.parent {
            parentController = controller
            if parentController is ModalContainerViewController {
                break
            }
        }
        return parentController as? ModalContainerViewController
    }
    
}
