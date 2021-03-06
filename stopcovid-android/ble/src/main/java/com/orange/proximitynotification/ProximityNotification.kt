/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/04/27 - for the TOUS-ANTI-COVID project
 */

package com.orange.proximitynotification

interface ProximityNotification {
    val isRunning: Boolean

    fun setUp(
        proximityPayloadProvider: ProximityPayloadProvider,
        proximityPayloadIdProvider: ProximityPayloadIdProvider,
        callback: ProximityNotificationCallback
    )

    suspend fun start()
    suspend fun stop()

    suspend fun notifyPayloadUpdated(proximityPayload: ProximityPayload)
}
