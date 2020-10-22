// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  UIView+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 09/04/2020 - for the TousAntiCovid project.
//

import UIKit

extension UIView {
    
    func addConstrainedSubview(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top).isActive = true
        subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom).isActive = true
        subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left).isActive = true
        subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.right).isActive = true
    }
    
    func addCenteredSubview(_ subview: UIView, size: CGSize? = nil) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0.0).isActive = true
        subview.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.0).isActive = true
        if let size = size {
            subview.widthAnchor.constraint(equalToConstant: size.width).isActive = true
            subview.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
    
}
