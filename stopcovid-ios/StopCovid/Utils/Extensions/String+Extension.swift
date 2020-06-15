// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  String+Extension.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 16/04/2020 - for the STOP-COVID project.
//

import UIKit

extension String {
    
    var isSingleEmoji: Bool { count == 1 && containsEmoji }
    var containsEmoji: Bool { contains { $0.isEmoji } }
    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }
    var emojiString: String { emojis.map { String($0) }.reduce("", +) }
    var emojis: [Character] { filter { $0.isEmoji } }
    var emojiScalars: [UnicodeScalar] { filter{ $0.isEmoji }.flatMap { $0.unicodeScalars } }
    
    var camelCased: String {
        if contains("_") {
            let allComponents: [String] = components(separatedBy: "_")
            var words: [String] = [(allComponents.first ?? "").lowercased()]
            words.append(contentsOf: allComponents[1..<allComponents.count].map { $0.lowercased().capitalized })
            return words.joined()
        } else {
            return self
        }
    }
    
    func removingEmojis() -> String {
        components(separatedBy: .symbols).filter { !$0.isEmpty }.joined().trimmingCharacters(in: .whitespaces)
    }
    
    func callPhoneNumber(from controller: UIViewController) {
        guard let url = URL(string: "tel://\(self)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let controller: UIAlertController = UIAlertController(title: "common.error.callImpossible".localized, message: nil, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
            controller.view.tintColor = Asset.Colors.tint.color
            controller.present(controller, animated: true, completion: nil)
        }
    }
    
    func cleaningForCSV(_ commaReplacement: String = ".") -> String {
        replacingOccurrences(of: ",", with: commaReplacement)
    }
    
}
