// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  BottomButtonContainerController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

final class BottomButtonContainerController: UIViewController {

    @IBOutlet private var button: CVButton!
    @IBOutlet private var secondaryButton: UIButton!
    @IBOutlet private var bottomBarView: UIView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var separator: UIView!
    private var embeddedController: UIViewController?
    private var buttonAction: (() -> ())?
    private var secondaryButtonAction: (() -> ())?
    private var buttonStyle: CVButton.Style = .primary
    private var accessHint: String?
    
    @IBOutlet private var buttonLeadingConstraint: NSLayoutConstraint?
    @IBOutlet private var buttonTrailingConstraint: NSLayoutConstraint?
    
    class func controller(_ embeddedController: UIViewController, buttonStyle: CVButton.Style = .primary, accessibilityHint: String? = nil) -> UIViewController {
        let containerController: BottomButtonContainerController = StoryboardScene.BottomButtonContainer.bottomButtonContainerController.instantiate()
        containerController.embeddedController = embeddedController
        containerController.buttonStyle = buttonStyle
        containerController.accessHint = accessibilityHint
        return containerController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setupEmbeddedController()
    }
    
    public func updateButton(title: String, action: @escaping () -> ()) {
        button.setTitle(title, for: .normal)
        buttonAction = action
        button.isUserInteractionEnabled = true
        setupAccessibility()
    }
    
    public func updateSecondaryButton(title: String?, action: (() -> ())?) {
        secondaryButton.setTitle(title, for: .normal)
        secondaryButtonAction = action
        secondaryButton.isHidden = title == nil
        setupAccessibility()
    }
    
    public func unlockButtons() {
        button.isUserInteractionEnabled = true
        secondaryButton.isUserInteractionEnabled = true
    }
    
    private func initUI() {
        view.backgroundColor = Asset.Colors.background.color
        separator.backgroundColor = Appearance.BottomBar.separatorColor
        bottomBarView.backgroundColor = Appearance.BottomBar.backgroundColor
        buttonLeadingConstraint?.constant = Appearance.BottomBar.Button.leftMargin
        buttonTrailingConstraint?.constant = Appearance.BottomBar.Button.rightMargin
        button.buttonStyle = buttonStyle
        secondaryButton.isHidden = true
        secondaryButton.setTitleColor(Asset.Colors.error.color, for: .normal)
        secondaryButton.titleLabel?.font = Appearance.Button.font
    }
    
    private func setupAccessibility() {
        button.isAccessibilityElement = true
        button.accessibilityLabel = button.title(for: .normal)?.removingEmojis()
        button.accessibilityHint = accessHint
        button.accessibilityTraits = .button
        secondaryButton.isAccessibilityElement = true
        secondaryButton.accessibilityLabel = secondaryButton.title(for: .normal)?.removingEmojis()
        secondaryButton.accessibilityTraits = .button
        secondaryButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    private func setupEmbeddedController() {
        guard let controller = embeddedController else { return }
        addChildViewController(controller, containerView: containerView)
    }

    @IBAction private func didTouchButton(_ sender: Any) {
        button.isUserInteractionEnabled = false
        buttonAction?()
    }
    
    @IBAction private func didTouchSecondaryButton(_ sender: Any) {
        secondaryButtonAction?()
    }
    
}

extension UIViewController {
    
    var bottomButtonContainerController: BottomButtonContainerController? {
        var parentController: UIViewController? = self
        while let controller = parentController?.parent {
            parentController = controller
            if parentController is BottomButtonContainerController {
                break
            }
        }
        return parentController as? BottomButtonContainerController
    }
    
}
