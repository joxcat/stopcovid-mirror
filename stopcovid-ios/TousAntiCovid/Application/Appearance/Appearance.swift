// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Appearance.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

enum Appearance {
    
    static let tintColor: UIColor = Asset.Colors.tint.color
    
    enum NavigationBar {
        static let titleFont: UIFont = .marianneExtraBold(size: 17.0)
    }
    
    enum Switch {
        static let onTint: UIColor = Asset.Colors.tint.color
    }
    
    enum TabBar {
        static var normalColor: UIColor { .lightGray }
        static var selectedColor: UIColor { Asset.Colors.tint.color }
    }
    
    enum Button {
        static let cornerRadius: CGFloat = 10.0
        static var font: UIFont? { UIFontMetrics(forTextStyle: .body).scaledFont(for: .medium(size: 17.0)) }
        static var linkFont: UIFont? { UIFontMetrics(forTextStyle: .body).scaledFont(for: .medium(size: 15.0)) }
        static let contentEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 20.0, right: 0.0)
        
        enum Primary {
            static var backgroundColor: UIColor { Asset.Colors.buttonBackground.color }
            static var titleColor: UIColor { Asset.Colors.buttonLabel.color }
        }
        
        enum Secondary {
            static var backgroundColor: UIColor { Asset.Colors.secondaryButtonBackground.color }
            static var titleColor: UIColor { Asset.Colors.secondaryButtonLabel.color }
        }
        
        enum Tertiary {
            static var backgroundColor: UIColor { .clear }
            static var titleColor: UIColor { Asset.Colors.tint.color }
        }
        
        enum Quaternary {
            static var backgroundColor: UIColor { .clear }
            static var titleColor: UIColor { Asset.Colors.secondaryButtonLabel.color }
        }
        
    }
    
    enum ShadowedButton {
        static var font: UIFont? { UIFontMetrics(forTextStyle: .body).scaledFont(for: .medium(size: 15.0)) }
    }
    
    enum Tag {
        static var font: UIFont { UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .regular(size: 11.0)) }
        static var textColor: UIColor {
            if #available(iOS 13.0, *) {
                return .label
            } else {
                return UIColor.white
            }
        }
    }
    
    enum Controller {
        static var backgroundColor: UIColor { Asset.Colors.background.color }
        static var cardTableViewBackgroundColor: UIColor { Asset.Colors.cardTableViewBackground.color }
        static var titleFont: UIFont { UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .marianneExtraBold(size: 34.0)) }
    }
    
    enum BottomBar {
        
        enum Button {
            static let leftMargin: CGFloat = 16.0
            static let rightMargin: CGFloat = 16.0
        }
        
        static let backgroundColor: UIColor = Asset.Colors.barBackground.color
        static var separatorColor: UIColor {
            if #available(iOS 13.0, *) {
                return .separator
            } else {
                return UIColor.black.withAlphaComponent(0.3)
            }
        }
        
    }
    
    enum Section {
        static var titleFont: UIFont  { .marianneBold(size: 24.0) }
    }
    
    enum Cell {
        
        enum Onboarding {
            static let stepBackgroundColor: UIColor = Asset.Colors.tint.color
            static var stepFont: UIFont { .medium(size: 28.0) }
            static let stepColor: UIColor = Asset.Colors.buttonLabel.color
        }
        
        enum Text {
            static var titleColor: UIColor {
                if #available(iOS 13.0, *) {
                    return .label
                } else {
                    return .black
                }
            }
            static var captionTitleFont: UIFont { UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .regular(size: 11.0)) }
            static var captionTitleFont2: UIFont { UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .marianneMedium(size: 12.0)) }
            static var headTitleFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .marianneBold(size: 25.0)) }
            static var headTitleFont2: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .marianneBold(size: 50.0)) }
            static var titleFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .marianneBold(size: 17.0)) }
            static var titleHighlightFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .medium(size: 17.0)) }
            static var subtitleColor: UIColor {
                if #available(iOS 13.0, *) {
                    return .label
                } else {
                    return .black
                }
            }
            static var placeholderColor: UIColor {
                if #available(iOS 13.0, *) {
                    return .placeholderText
                } else {
                    return .lightGray
                }
            }
            static var disabledColor: UIColor {
                if #available(iOS 13.0, *) {
                    return .tertiaryLabel
                } else {
                    return .lightGray
                }
            }
            static var captionTitleColor: UIColor { Asset.Colors.captionTitle.color }
            static var accessoryFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .regular(size: 12.0)) }
            static var subtitleFont: UIFont { UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .regular(size: 15.0)) }
            static var standardFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .regular(size: 17.0)) }
            static var standardBigFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .bold(size: 17.0)) }
            
            static var headerTitleColor: UIColor { Asset.Colors.tint.color }
            static var valueTitleFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .semibold(size: 12.0)) }
            static var valueFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .marianneBold(size: 24.0)) }

            static var errorColor: UIColor { Asset.Colors.error.color }
            
            static var footerFont: UIFont { UIFontMetrics(forTextStyle: .body).scaledFont(for: .regular(size: 13.0)) }
        }
        
        enum Image {
            static let tintColor: UIColor = Asset.Colors.tint.color
            static let size: CGSize = CGSize(width: 24.0, height: 24.0)
            
            static let defaultRatio: CGFloat = 375.0 / 210.0
            static let onboardingControllerRatio: CGFloat = 375.0 / 288.0
        }
        
        enum Notification {
            static let backgroundColor: UIColor = Asset.Colors.notificationCellBackground.color
            static let riskBackgroundColor: UIColor = Asset.Colors.notificationRiskCellBackground.color
        }
        
        static var cardBackgroundColor: UIColor { Asset.Colors.cardTableViewCellBackground.color }
        static let leftMargin: CGFloat = 16.0
        static let rightMargin: CGFloat = 16.0
        
    }
    
    enum BottomMessage {
        static var font: UIFont { UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .bold(size: 13.0)) }
    }
    
}

extension CVRow.Theme {
    
    static let standardText: CVRow.Theme = CVRow.Theme(topInset: 15.0,
                                                       bottomInset: 15.0,
                                                       textAlignment: .natural,
                                                       titleFont: { .regular(size: 17.0) },
                                                       titleColor: Appearance.Cell.Text.titleColor,
                                                       subtitleFont: { .regular(size: 12.0) },
                                                       subtitleColor: Appearance.Cell.Text.subtitleColor,
                                                       separatorLeftInset: Appearance.Cell.leftMargin)
    
    static let standardInvertedText: CVRow.Theme = CVRow.Theme(topInset: 15.0,
                                                       bottomInset: 15.0,
                                                       textAlignment: .natural,
                                                       titleFont: { .regular(size: 12.0) },
                                                       titleColor: Appearance.Cell.Text.subtitleColor,
                                                       subtitleFont: { .regular(size: 17.0) },
                                                       subtitleColor: Appearance.Cell.Text.titleColor,
                                                       separatorLeftInset: Appearance.Cell.leftMargin)
    
}
