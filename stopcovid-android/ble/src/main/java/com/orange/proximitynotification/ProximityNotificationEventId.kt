/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Authors
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Created by Orange / Date - 2020/09/14 - for the TOUS-ANTI-COVID project
 */

package com.orange.proximitynotification

import com.orange.proximitynotification.ProximityNotificationEventId.Category.BLE_ADVERTISER
import com.orange.proximitynotification.ProximityNotificationEventId.Category.BLE_GATT
import com.orange.proximitynotification.ProximityNotificationEventId.Category.BLE_SCANNER
import com.orange.proximitynotification.ProximityNotificationEventId.Category.PROXIMITY_NOTIFICATION

enum class ProximityNotificationEventId(val category: Category) {

    BLE_ADVERTISER_START(BLE_ADVERTISER),
    BLE_ADVERTISER_START_ERROR(BLE_ADVERTISER),
    BLE_ADVERTISER_START_SUCCESS(BLE_ADVERTISER),
    BLE_ADVERTISER_STOP(BLE_ADVERTISER),
    BLE_ADVERTISER_STOP_ERROR(BLE_ADVERTISER),
    BLE_ADVERTISER_STOP_SUCCESS(BLE_ADVERTISER),

    BLE_GATT_START(BLE_GATT),
    BLE_GATT_START_ERROR(BLE_GATT),
    BLE_GATT_START_SUCCESS(BLE_GATT),
    BLE_GATT_STOP(BLE_GATT),
    BLE_GATT_STOP_ERROR(BLE_GATT),
    BLE_GATT_STOP_SUCCESS(BLE_GATT),
    BLE_GATT_CONNECT_ERROR(BLE_GATT),
    BLE_GATT_CONNECT_SUCCESS(BLE_GATT),
    BLE_GATT_REQUEST_REMOTE_RSSI(BLE_GATT),
    BLE_GATT_REQUEST_REMOTE_RSSI_TIMEOUT(BLE_GATT),
    BLE_GATT_REQUEST_REMOTE_RSSI_ERROR(BLE_GATT),
    BLE_GATT_REQUEST_REMOTE_RSSI_SUCCESS(BLE_GATT),
    BLE_GATT_EXCHANGE_PAYLOAD(BLE_GATT),
    BLE_GATT_EXCHANGE_PAYLOAD_TIMEOUT(BLE_GATT),
    BLE_GATT_EXCHANGE_PAYLOAD_ERROR(BLE_GATT),
    BLE_GATT_EXCHANGE_PAYLOAD_SUCCESS(BLE_GATT),
    BLE_GATT_ON_CHARACTERISTIC_WRITE_REQUEST(BLE_GATT),
    BLE_GATT_ON_CHARACTERISTIC_WRITE_REQUEST_ERROR(BLE_GATT),
    BLE_GATT_ON_CHARACTERISTIC_WRITE_REQUEST_SUCCESS(BLE_GATT),

    BLE_SCANNER_START(BLE_SCANNER),
    BLE_SCANNER_START_ERROR(BLE_SCANNER),
    BLE_SCANNER_START_SUCCESS(BLE_SCANNER),
    BLE_SCANNER_STOP(BLE_SCANNER),
    BLE_SCANNER_STOP_ERROR(BLE_SCANNER),
    BLE_SCANNER_STOP_SUCCESS(BLE_SCANNER),
    BLE_SCANNER_ON_BATCH_SCAN_RESULT(BLE_SCANNER),
    BLE_SCANNER_ON_SCAN_RESULT(BLE_SCANNER),

    PROXIMITY_NOTIFICATION_START(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_START_BLE(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_STOP(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_STOP_BLE(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_PAYLOAD_UPDATED(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_BLE_SETTINGS_UPDATED(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_BLUETOOTH_DISABLED(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_BLUETOOTH_ENABLED(PROXIMITY_NOTIFICATION),
    PROXIMITY_NOTIFICATION_RESTART_BLUETOOTH(PROXIMITY_NOTIFICATION),

    BLE_PROXIMITY_NOTIFICATION_WITHOUT_ADVERTISER(PROXIMITY_NOTIFICATION),

    BLE_PROXIMITY_NOTIFICATION_FACTORY(PROXIMITY_NOTIFICATION);


    enum class Category {
        /**
         * BLE advertising error
         */
        BLE_ADVERTISER,

        /**
         * BLE scanner error
         */
        BLE_SCANNER,

        /**
         * BLE gatt error
         */
        BLE_GATT,

        /**
         * Proximity notification component error
         */
        PROXIMITY_NOTIFICATION
    }


}