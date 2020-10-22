/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/27 - for the TousAntiCovid project
 */

import Foundation

/// The errors returned by a filtering operation.
public enum ProximityFilterError: Error {
    
    /// The duration of the period over which the RSSIs where received is too short.
    case durationTooShort
    
    /// The risk associated with the RSSIs is too low.
    case riskTooLow
}
