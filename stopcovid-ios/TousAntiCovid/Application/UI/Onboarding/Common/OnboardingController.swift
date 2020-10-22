// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  OnboardingController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

class OnboardingController: CVTableViewController, LocalizationsChangesObserver {

    override var prefersHomeIndicatorAutoHidden: Bool { false }
    
    var isOpenedFromOnboarding: Bool = true
    var backButtonItem: UIBarButtonItem!
    var bottomButtonTitle: String { fatalError("Must be overriden") }
    
    private let didContinue: (() -> ())?
    private let deinitBlock: (() -> ())?
    
    init(isOpenedFromOnboarding: Bool = true, didContinue: (() -> ())? = nil, deinitBlock: (() -> ())? = nil) {
        self.isOpenedFromOnboarding = isOpenedFromOnboarding
        self.didContinue = didContinue
        self.deinitBlock = deinitBlock
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use default init() method.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        LocalizationsManager.shared.addObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBottomBarButton()
        backButtonItem?.tintColor = Asset.Colors.tint.color
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        backButtonItem?.tintColor = .clear
    }
    
    deinit {
        LocalizationsManager.shared.removeObserver(self)
        deinitBlock?()
    }
    
    func updateTitle() {
        navigationChildController?.updateTitle(title)
    }
    
    override func createRows() -> [CVRow] { [] }
    
    func bottomContainerButtonTouched() {
        didContinue?()
    }
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
        updateBottomBarButton()
    }
    
    func createCustomLeftBarButtonItem() -> UIBarButtonItem {
        UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationChildController?.scrollViewDidScroll(scrollView)
    }
    
    @objc func didTouchBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        if !isOpenedFromOnboarding {
            if let controller = navigationChildController {
                controller.updateLeftBarButtonItem(createCustomLeftBarButtonItem())
            } else {
                navigationItem.leftBarButtonItem = createCustomLeftBarButtonItem()
            }
        } else if navigationController?.viewControllers.count ?? 0 > 1 {
            backButtonItem = UIBarButtonItem.back(target: self, action: #selector(didTouchBackButton))
            backButtonItem.accessibilityHint = "accessibility.hint.onboarding.back.label".localized
            navigationChildController?.updateLeftBarButtonItem(backButtonItem)
        }
    }
    
    private func updateBottomBarButton() {
        bottomButtonContainerController?.updateButton(title: bottomButtonTitle) { [weak self] in
            self?.bottomContainerButtonTouched()
        }
    }
    
    @objc func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
}
