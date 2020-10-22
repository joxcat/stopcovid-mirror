//
//  BottomMessageContainerViewController.swift
//  COVID-19
//
//  Created by Nicolas on 10/04/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

final class BottomMessageContainerViewController: UIViewController {

    @IBOutlet private var containerView: UIView!
    private var embeddedController: UIViewController?
    
    class func controller(_ embeddedController: UIViewController) -> UIViewController {
        let containerController: BottomMessageContainerViewController = StoryboardScene.BottomMessageContainer.bottomMessageContainerControllerViewController.instantiate()
        containerController.embeddedController = embeddedController
        return containerController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmbeddedController()
    }
    
    private func setupEmbeddedController() {
        guard let controller = embeddedController else { return }
        addChildViewController(controller, containerView: containerView)
    }

}
