# ProximityNotification SDK for iOS

`ProximityNotification` SDK uses Bluetooth Low Energy (BLE) in order to exchange data with proximity nearby.

Each time a device is nearby a `ProximityInfo` is notified. `ProximityInfo` contains following information:
- Proximity payload containing exchanged data.
- Proximity timestamp.
- Some metadata such as BLE calibrated received signal strength indicator (RSSI) and transmitting (TX) power level.

In order to use `ProximityNotification`, the application must declare `bluetooth-central` and `bluetooth-peripheral` background modes.

Then, you must create a `ProximityNotificationService` object with the following settings and a closure to monitor the state changes:
- The service unique identifier.
- The characteristic unique identifier.
- The calibrated TX power level of your device.
- The RSSI compensation gain of your device.

```swift
import ProximityNotification

let bleSettings = BluetoothSettings(serviceUniqueIdentifier: "",
                                    serviceCharacteristicUniqueIdentifier: "",
                                    txCompensationGain: 0,
                                    rxCompensationGain: 0)
let stateChangedHandler: StateChangedHandler = { state in }
let service = ProximityNotificationService(settings: ProximityNotificationSettings(bluetoothSettings: bleSettings),
                                           stateChangedHandler: stateChangedHandler)
```

To start the service, you need to call `start` with the following parameters:
- The closure called when the SDK will send a payload to a remote.
- The closure called when a `ProximityInfo` is notified.
- The closure called to extract an identifier from a payload.

```swift
let proximityPayloadProvider: ProximityPayloadProvider = {
}

let proximityInfoUpdateHandler: ProximityInfoUpdateHandler = { proximity in
}

let identifierFromProximityPayload: IdentifierFromProximityPayload = { payload in
}

service.start(proximityPayloadProvider: proximityPayloadProvider,
              proximityInfoUpdateHandler: proximityInfoUpdateHandler,
              identifierFromProximityPayload: identifierFromProximityPayload)
```

To stop the service, you can call `stop`.

```swift
service.stop()
```
