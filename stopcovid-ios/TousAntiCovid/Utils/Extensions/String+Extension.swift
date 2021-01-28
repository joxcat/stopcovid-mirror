// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  String+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 16/04/2020 - for the TousAntiCovid project.
//

import UIKit
import CommonCrypto

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
    
    var isUuidCode: Bool { self ~= "^[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}$" }
    var isShortCode: Bool { self ~= "^[A-Za-z0-9]{6}$" }
    var isPostalCode: Bool { self ~= "^[0-9]{5}$" }

    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range: NSRange = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
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
    
    func share(from controller: UIViewController, fromButton: UIButton? = nil) {
        let activityController: UIActivityViewController = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        if let button = fromButton {
            activityController.popoverPresentationController?.setSourceButton(button)
        }
        controller.present(activityController, animated: true, completion: nil)
    }
    
    func cleaningForServerFileName() -> String {
        clearingDiacritics().clearingSpecialCharacters()
    }
    
    func clearingDiacritics() -> String {
        folding(options: .diacriticInsensitive, locale: nil)
    }
    
    func clearingSpecialCharacters() -> String {
        let pattern: String = "[^A-Za-z0-9]+"
        return replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
    }
    
    func formattingValueWithThousandsSeparatorIfPossible() -> String {
        if let numberValue = Int(self) {
            return numberValue.formattedWithThousandsSeparator()
        } else {
            return self
        }
    }
    
    func accessibilityNumberFormattedString() -> String {
        guard let intValue = Int(self) else { return self }
        let numberValue: NSNumber = NSNumber(integerLiteral: intValue)
        return NumberFormatter.localizedString(from: numberValue, number: .spellOut)
    }
    
    func qrCode() -> UIImage? {
        guard let data = data(using: .utf8) else { return nil }
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform: CGAffineTransform = CGAffineTransform(scaleX: 5, y: 5)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    func sha256() -> String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input: NSData) -> NSData {
        let digestLength: Int = Int(CC_SHA256_DIGEST_LENGTH)
        var hash: [UInt8] = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
}
