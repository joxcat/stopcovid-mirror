// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVRow.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

struct CVRow {

    struct Theme {
        var backgroundColor: UIColor?
        var topInset: CGFloat?
        var bottomInset: CGFloat?
        var leftInset: CGFloat?
        var rightInset: CGFloat?
        var textAlignment: NSTextAlignment = .center
        var titleFont: (() -> UIFont) = { Appearance.Cell.Text.titleFont }
        var titleHighlightFont: (() -> UIFont) = { Appearance.Cell.Text.titleFont }
        var titleColor: UIColor = Appearance.Cell.Text.titleColor
        var titleHighlightColor: UIColor = Asset.Colors.tint.color
        var subtitleFont: (() -> UIFont) = { Appearance.Cell.Text.subtitleFont }
        var subtitleColor: UIColor = Appearance.Cell.Text.subtitleColor
        var placeholderColor: UIColor = Appearance.Cell.Text.placeholderColor
        var accessoryTextFont: (() -> UIFont?)?
        var imageTintColor: UIColor?
        var imageSize: CGSize?
        var imageRatio: CGFloat?
        var separatorLeftInset: CGFloat?
        var separatorRightInset: CGFloat?
        var buttonStyle: CVButton.Style = .primary
        var maskedCorners: CACornerMask = .all
    }
    
    static var empty: CVRow {
        CVRow(xibName: .emptyCell,
              theme: CVRow.Theme(topInset: 0.0, bottomInset: 0.0))
    }
    
    var title: String?
    var subtitle: String?
    var placeholder: String?
    var accessoryText: String?
    var titleHighlightText: String?
    var image: UIImage?
    var buttonTitle: String?
    var isOn: Bool?
    var xibName: XibName
    var theme: Theme = Theme()
    var enabled: Bool = true
    var associatedValue: Any? = nil
    var textFieldKeyboardType: UIKeyboardType?
    var textFieldReturnKeyType: UIReturnKeyType?
    var textFieldContentType: UITextContentType?
    var textFieldCapitalizationType: UITextAutocapitalizationType?
    var textFieldRegex: String?
    var minimumDate: Date?
    var maximumDate: Date?
    var initialDate: Date?
    var datePickerMode: UIDatePicker.Mode?
    var selectionActionWithCell: ((_ cell: CVTableViewCell) -> ())?
    var selectionAction: (() -> ())?
    var secondarySelectionAction: (() -> ())?
    var tertiarySelectionAction: (() -> ())?
    var quaternarySelectionAction: (() -> ())?
    var quinarySelectionAction: (() -> ())?
    var senarySelectionAction: (()-> ())?
    var willDisplay: ((_ cell: CVTableViewCell) -> ())?
    var valueChanged: ((_ value: Any?) -> ())?
    var didValidateValue: ((_ value: Any?, _ cell: CVTableViewCell) -> ())?
    var displayValueForValue: ((_ value: Any?) -> String?)?
    
    static func emptyFor(topInset: CGFloat, bottomInset: CGFloat, showSeparator: Bool = false) -> CVRow {
        CVRow(xibName: .emptyCell,
              theme: CVRow.Theme(topInset: topInset,
                                 bottomInset: bottomInset,
                                 separatorLeftInset: showSeparator ? 0.0 : nil,
                                 separatorRightInset: showSeparator ? 0.0 : nil))
    }
    
}
