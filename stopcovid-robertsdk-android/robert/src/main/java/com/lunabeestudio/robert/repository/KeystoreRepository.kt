/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/04/05 - for the STOP-COVID project
 */

package com.lunabeestudio.robert.repository

import com.lunabeestudio.robert.datasource.LocalKeystoreDataSource
import com.lunabeestudio.robert.extension.randomize
import com.lunabeestudio.robert.model.NoSharedKeyException
import com.lunabeestudio.robert.model.RobertResultData

internal class KeystoreRepository(
    private val keystoreDataSource: LocalKeystoreDataSource) {

    private var cachedSharedKey: ByteArray? = null

    fun saveSharedKey(sharedKey: ByteArray) {
        clearCachedKey()
        keystoreDataSource.saveSharedKey(sharedKey)
    }

    fun getSharedKey(): RobertResultData<ByteArray> {
        if (cachedSharedKey == null) {
            val result = keystoreDataSource.getSharedKey()
            when (result) {
                is RobertResultData.Success -> cachedSharedKey = result.data
                is RobertResultData.Failure -> return result

            }
        }

        cachedSharedKey?.let {
            return RobertResultData.Success(it)
        } ?: return RobertResultData.Failure(NoSharedKeyException("cachedSharedKey unexpectedly null"))
    }

    fun removeSharedKey() {
        clearCachedKey()
        keystoreDataSource.removeSharedKey()
    }

    var timeStart: Long?
        get() = keystoreDataSource.timeStart
        set(value) {
            keystoreDataSource.timeStart = value
        }

    var atRisk: Boolean?
        get() = keystoreDataSource.atRisk
        set(value) {
            keystoreDataSource.atRisk = value
        }

    var lastExposureTimeframe: Int?
        get() = keystoreDataSource.lastExposureTimeframe
        set(value) {
            keystoreDataSource.lastExposureTimeframe = value
        }

    var proximityActive: Boolean?
        get() = keystoreDataSource.proximityActive
        set(value) {
            keystoreDataSource.proximityActive = value
        }

    var isSick: Boolean?
        get() = keystoreDataSource.isSick
        set(value) {
            keystoreDataSource.isSick = value
        }

    private fun clearCachedKey() {
        cachedSharedKey?.randomize()
        cachedSharedKey = null
    }
}