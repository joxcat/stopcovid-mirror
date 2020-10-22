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

/// The possible filtering modes.
public enum ProximityFilterMode {
    
    /// An all-or-nothing mode where RSSIs are kept if the duration of the period over which they were received exceeds a given threshold.
    case full
    
    /// A mode that first performs steps from the full mode, then clips the RSSIs that exceed a given threshold and finally computes the intermediate risks.
    case medium
    
    /// A mode that first performs steps from the medium mode and then computes the risk from the intermediate risks, as well as additional relevant output values.
    case risks
}
