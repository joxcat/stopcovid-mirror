/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/12 - for the TousAntiCovid project
 */

import Foundation

/// The version of the ProximityNotification library according to the semantic versioning specification.
public struct ProximityNotificationVersion {
    
    /// The major version number. Should be incremented when making incompatible API changes.
    public static let major = 1
    
    /// The minor version number. Should be incremented when adding functionality in a backward compatible manner.
    public static let minor = 1
    
    /// The patch version number. Should be incremented when making backward compatible bug fixes.
    public static let patch = 1
    
    /// A textual description of the current version.
    public static var current: String {
        return "\(major).\(minor).\(patch)"
    }
}
