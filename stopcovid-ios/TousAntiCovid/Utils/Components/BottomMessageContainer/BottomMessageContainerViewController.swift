// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BottomMessageContainerViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 10/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class BottomMessageContainerViewController: UIViewController {

    var messageDidTouch: (() -> ())?
    var messageHeight: CGFloat {
        messageLabel.text?.isEmpty != false ? 0.0 : messageView.frame.height
    }
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var messageView: UIView!
    @IBOutlet private var messageLabel: UILabel!
    private var embeddedController: UIViewController?
    
    class func controller(_ embeddedController: UIViewController) -> UIViewController {
        let containerController: BottomMessageContainerViewController = StoryboardScene.BottomMessageContainer.bottomMessageContainerViewController.instantiate()
        containerController.embeddedController = embeddedController
        return containerController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmbeddedController()
        messageView.alpha = 0.0
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.isAccessibilityElement = true
    }
    
    func updateMessage(text: String? = nil, font: UIFont? = nil, textColor: UIColor? = nil, backgroundColor: UIColor? = nil, actionHint: String? = nil, completion: (() -> ())? = nil) {
        UIView.transition(with: messageView, duration: 0.2, options: [.transitionCrossDissolve], animations: {
            self.messageView.backgroundColor = backgroundColor
            self.messageLabel.text = text
            self.messageLabel.font = font
            self.messageLabel.textColor = textColor
            self.messageView.alpha = text == nil ? 0.0 : 1.0
            self.view.layoutIfNeeded()
        }) { _ in
            if let hint = actionHint {
                self.messageLabel.accessibilityTraits = .button
                self.messageLabel.accessibilityHint = hint.removingEmojis()
            } else {
                self.messageLabel.accessibilityTraits = .staticText
                self.messageLabel.accessibilityHint = nil
            }
            completion?()
        }
    }
    
    private func setupEmbeddedController() {
        guard let controller = embeddedController else { return }
        addChildViewController(controller, containerView: containerView)
    }
    
    @IBAction private func messageViewDidTap(_ sender: Any) {
        messageDidTouch?()
    }

}

extension UIViewController {
    
    var bottomMessageContainerController: BottomMessageContainerViewController? {
        var parentController: UIViewController? = self
        while let controller = parentController?.parent {
            parentController = controller
            if parentController is BottomMessageContainerViewController {
                break
            }
        }
        return parentController as? BottomMessageContainerViewController
    }
    
}
