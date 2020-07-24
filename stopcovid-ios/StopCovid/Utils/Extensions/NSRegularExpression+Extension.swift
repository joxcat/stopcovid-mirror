//
//  NSRegularExpression+Extension.swift
//  StopCovid
//
//  Created by Nicolas on 13/07/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
    
    func matches(_ string: String) -> Bool {
        let range: NSRange = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
    
}
