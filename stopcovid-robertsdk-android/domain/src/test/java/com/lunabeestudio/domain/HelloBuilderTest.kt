/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Lunabee Studio / Date - 2020/04/05 - for the STOP-COVID project
 */

package com.lunabeestudio.domain

import com.google.common.truth.Truth.assertThat
import com.googlecode.zohhak.api.TestWith
import com.googlecode.zohhak.api.runners.ZohhakRunner
import com.lunabeestudio.domain.model.EphemeralBluetoothIdentifier
import com.lunabeestudio.domain.model.Hello
import com.lunabeestudio.domain.model.HelloBuilder
import com.lunabeestudio.domain.model.HelloSettings
import org.junit.runner.RunWith
import java.nio.ByteBuffer
import java.util.Base64

@RunWith(ZohhakRunner::class)
class HelloBuilderTest {
    @TestWith(
        coercers = [DomainCoercion::class],
        value = [
            "46, 53544F50434F5631, string, 4276036795200, 70.83.84.79.80.67.79.86.49.-93.59.-49.57.-64.113.102"]
    )
    fun `build given ecc, ebid, key and time should return expected`(ecc: String,
        ebid: String,
        key: String,
        currentTimeMillis: Long,
        expected: Hello) {

        val buffer = ByteBuffer
            .allocate(8)
            .putLong(ebid.toLong(16))

        buffer.flip()

        val builder = HelloBuilder(HelloSettings(),
            EphemeralBluetoothIdentifier(0, 0, byteArrayOf(ecc.toByte(16)), buffer.array()),
            key.toByteArray(Charsets.UTF_8))

        val hello = builder.build(currentTimeMillis)

        assertThat(hello).isEqualTo(expected)
    }

    @TestWith(
        coercers = [DomainCoercion::class],
        value = [
            "eg==, HivsWMEbkHo=, I5lqt1XfQKstC8TYw6YOVhzfwvsTnJPfHLbwj3HZzTw=, 1588752561000, 122.30.43.-20.88.-63.27.-112.122.-17.49.-99.46.14.-13.80"]
    )
    fun `build given ecc64, ebid64, key64 and time should return expected`(
        ecc64: String,
        ebid64: String,
        key64: String,
        currentTimeMillis: Long,
        expected: Hello) {

        val builder = HelloBuilder(HelloSettings(),
            EphemeralBluetoothIdentifier(
                ntpStartTimeS = 0,
                ntpEndTimeS = 0,
                ecc = Base64.getDecoder().decode(ecc64),
                ebid = Base64.getDecoder().decode(ebid64)),
            key = Base64.getDecoder().decode(key64))

        val hello = builder.build(currentTimeMillis)

        assertThat(hello).isEqualTo(expected)
    }
}