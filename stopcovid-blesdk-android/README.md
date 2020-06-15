# ProximityNotification SDK for Android

ProximityNotification SDK uses Bluetooth Low Energy (BLE) in order to exchange data with proximity nearby

Each time a device is nearby a ProximityInfo is notified. ProximityInfo contains following information:
- Proximity payload containing exchanged data
- Proximity timestamp
- Some metadata such as BLE calibrated RSSI, txPowerLevel


In order to use ProximityNotification you must override ProximityNotificationService.
ProximityNotificationService is a foreground service.

Don't forget to declare foregroundServiceType into your AndroidManifest.xml

```xml
<service
            android:name="your.service.overriding.ProximityNotificationService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location|connectedDevice"/>
```

In your service implementation you will have to declare the settings of the ProximityNotification SDK
such as service UUID used to advertise and scan in BLE. 
Please refer to BleSettings

```kotlin

override val bleSettings : BleSettings by lazy { BleSettings (
    serviceUuid = UUID.fromString("Service UUID"),
    servicePayloadCharacteristicUuid = UUID.fromString("Service payload Characteristic UUID"),
    backgroundServiceManufacturerDataIOS = byteArrayOf(), // Byte array of manufacturer data advertised by iOS in background. It depends on your service UUID
    txCompensationGain = 0, // Calibrated TxPowerLevel of your device
    rxCompensationGain = 0, // RSSI compensation gain of your device
    )
}

override fun buildForegroundServiceNotification(): Notification {
    // Build and return notification to display for the foreground service
}

override suspend fun current(): ProximityPayload {
        return withContext(Dispatchers.Default) {
            // here your must return current ProximityPayload to exchange
            // ProximityPayload must be 16 bytes length
            // ProximityPayload(ByteArray(16))
        }
    }

```

To start the service just call start()
```kotlin
service.start()
```

To stop the service just call stop()
```kotlin
service.stop()
```

In case of proximity payload renewal notify the Proximity Notification service calling
```kotlin
service.notifyProximityPayloadUpdated()
```