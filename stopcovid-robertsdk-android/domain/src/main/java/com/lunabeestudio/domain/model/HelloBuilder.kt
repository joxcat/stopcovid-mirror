/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/04/05 - for the STOP-COVID project
 */

package com.lunabeestudio.domain.model

import com.lunabeestudio.domain.extension.unixTimeMsToNtpTimeS
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class HelloBuilder(
    private val settings: HelloSettings,
    private val ephemeralBluetoothIdentifier: EphemeralBluetoothIdentifier,
    key: ByteArray
) {
    private val mac: Mac

    init {
        val secretKeySpec = SecretKeySpec(key, settings.algorithm)
        mac = Mac.getInstance(settings.algorithm)
        mac.init(secretKeySpec)
    }

    /**
     * Build an [Hello] with the given timestamp
     *
     * @param currentTimeMillis Unix timestamp in millis
     * @return A complete [Hello] ready to send
     */
    fun build(currentTimeMillis: Long = System.currentTimeMillis()): Hello {
        val time = currentTimeMillis.unixTimeMsToNtpTimeS()

        val timeByteArray = byteArrayOf(
            (time shr 8).toByte(),
            time.toByte()
        )

        val message = ephemeralBluetoothIdentifier.ecc + ephemeralBluetoothIdentifier.ebid + timeByteArray
        val mac = mac.doFinal(byteArrayOf(settings.prefix) + message).copyOfRange(0, 5)

        return Hello(ephemeralBluetoothIdentifier.ecc, ephemeralBluetoothIdentifier.ebid, timeByteArray, mac)
    }
}