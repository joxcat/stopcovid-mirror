/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/11/05 - for the STOP-COVID project
 */

package com.lunabeestudio.robert

import com.lunabeestudio.domain.model.Hello
import com.lunabeestudio.domain.model.LocalProximity
import com.lunabeestudio.robert.model.RobertResult
import com.lunabeestudio.robert.model.RobertResultData

interface RobertManager {

    val isRegistered: Boolean

    val isProximityActive: Boolean

    val isAtRisk: Boolean

    val lastExposureTimeframe: Int

    val isSick: Boolean

    suspend fun register(application: RobertApplication, captcha: String): RobertResult

    fun activateProximity(application: RobertApplication)

    fun deactivateProximity(application: RobertApplication)

    suspend fun updateStatus(): RobertResult

    fun clearOldData()

    suspend fun report(token: String): RobertResult

    suspend fun storeLocalProximity(vararg localProximity: LocalProximity)

    fun getCurrentHello(): RobertResultData<Hello>

    suspend fun eraseLocalHistory(): RobertResult

    suspend fun eraseRemoteExposureHistory(): RobertResult

    suspend fun eraseRemoteAlert(): RobertResult

    suspend fun quitStopCovid(application: RobertApplication): RobertResult
}
