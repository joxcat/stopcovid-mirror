/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/05/08 - for the TOUS-ANTI-COVID project
 */

package com.orange.proximitynotification.ble

import com.google.common.truth.Truth.assertThat
import com.nhaarman.mockitokotlin2.atLeastOnce
import com.nhaarman.mockitokotlin2.doReturn
import com.nhaarman.mockitokotlin2.mock
import com.nhaarman.mockitokotlin2.never
import com.nhaarman.mockitokotlin2.verify
import com.nhaarman.mockitokotlin2.whenever
import com.orange.proximitynotification.ProximityInfo
import com.orange.proximitynotification.ble.calibration.BleRssiCalibration
import org.junit.Test
import java.util.Date

class BleRecordMapperTest {

    @Test
    fun toProximityInfo_given_raw_RSSI() {

        // Given
        val rssi = 3
        val txPowerLevel = 2
        val rxCompensationGain = 1
        val timestamp = Date()
        val payload = payload(txPowerLevel = txPowerLevel)
        val record =
            record(payload = payload, rssi = rssi, timestamp = timestamp, isRssiCalibrated = false)
        val calibratedRssi = BleRssiCalibration.calibrate(
            rssi = rssi,
            rxCompensationGain = rxCompensationGain,
            txCompensationGain = txPowerLevel
        )

        val settings: BleSettings = mock()
        whenever(settings.rxCompensationGain).doReturn(rxCompensationGain)
        val mapper = BleRecordMapper(settings)

        // When
        val result = mapper.toProximityInfo(record)

        // Then
        val expected = ProximityInfo(
            payload = payload.proximityPayload,
            timestamp = timestamp,
            metadata = BleProximityMetadata(
                rawRssi = rssi,
                calibratedRssi = calibratedRssi,
                txPowerLevel = txPowerLevel
            )
        )
        assertThat(result).isEqualTo(expected)
        verify(settings, atLeastOnce()).rxCompensationGain

    }


    @Test
    fun toProximityInfo_given_already_calibrated_RSSI() {

        // Given
        val rssi = 3
        val txPowerLevel = 2
        val timestamp = Date()
        val payload = payload(txPowerLevel = txPowerLevel)
        val record =
            record(payload = payload, rssi = rssi, timestamp = timestamp, isRssiCalibrated = true)

        val settings: BleSettings = mock()
        val mapper = BleRecordMapper(settings)

        // When
        val result = mapper.toProximityInfo(record)

        // Then
        val expected = ProximityInfo(
            payload = payload.proximityPayload,
            timestamp = timestamp,
            metadata = BleProximityMetadata(
                rawRssi = rssi,
                calibratedRssi = rssi,
                txPowerLevel = txPowerLevel
            )
        )
        assertThat(result).isEqualTo(expected)
        verify(settings, never()).rxCompensationGain

    }
}