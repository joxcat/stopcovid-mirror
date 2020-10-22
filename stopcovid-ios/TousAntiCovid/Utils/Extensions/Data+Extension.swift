// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Data+Extension.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 07/05/2020 - for the TousAntiCovid project.
//


import Foundation

extension Data {
    
    mutating func wipe() {
        guard let range = Range(NSMakeRange(0, count)) else { return }
        resetBytes(in: range)
    }
    
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
    
}
