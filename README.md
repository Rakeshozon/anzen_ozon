# Anzen Ozon — Women’s Safety (Pepper‑Spray Trigger) — **Alert‑Only ESP8266 Mode**

**NOTE:** This repo implements a women’s‑safety alert system where a mechanical trigger on a pepper‑spray canister notifies an app. The **ESP8266 device only sends a lightweight alert event** (no GPS/GSM). The **mobile app obtains the live GPS location** from the phone when it receives the alert and is responsible for notifying emergency contacts.

> ⚠️ Legal & safety reminder: make sure your device use and modifications comply with local law. Do not use this system to harm anyone. The repository documents an alert system only — the author (you) is responsible for safe, legal deployment.

---

## Table of contents

* [Project overview](#project-overview)
* [What changed — design decision](#what-changed---design-decision)
* [How it works (high level)](#how-it-works-high-level)
* [Hardware & wiring (ESP8266 only)](#hardware--wiring-esp8266-only)
* [ESP8266 firmware (alert-only example)](#esp8266-firmware-alert-only-example)
* [Firebase data model & recommended rules](#firebase-data-model--recommended-rules)
* [Flutter app behavior (required)](#flutter-app-behavior-required)
* [Security, privacy & best practices](#security-privacy--best-practices)
* [Testing & deployment checklist](#testing--deployment-checklist)
* [Contributing](#contributing)
* [License](#license)

---

## Project overview

This system converts a pepper‑spray mechanical trigger into an emergency alert sender. When the user presses the spray (activates the trigger), a momentary switch changes state. The ESP8266 detects this and pushes a compact alert event to Firebase Realtime Database (or Firestore). The mobile app (signed in and paired with the device) listens for that alert; once it detects an alert it:

1. Immediately obtains the phone’s **live GPS location** (with user permission),
2. Sends that location + timestamp + device metadata to emergency contacts (via SMS/push/call), and
3. Updates Firebase with the resolved state or any additional info.

This approach keeps the embedded device simple, cheap, and low‑power while leveraging the smartphone for accurate location and contact actions.

---

## What changed — design decision

* **No GPS or GSM on ESP8266.** The device only reports a trigger event.
* **App-centric location & notifications.** The app must have location permissions and the ability to send SMS/push/call (or use server-side SMS).
* **Benefits:** cheaper hardware, lower power, simpler firmware, and accurate location (phone GPS).
* **Tradeoffs:** requires paired smartphone to be nearby and connected to the internet (or have mobile data).

---

## How it works (high level)

```text
[ Pepper Spray Trigger ] --switch--> [ESP8266] --Wi‑Fi--> [Firebase Realtime DB: /alerts (push event) ]
                                                               |
                                                               v
                                              [ Flutter App (mobile) listening to /alerts ) ]
                                                               |
                       App reads phone GPS (FINE_LOCATION) & sends SMS/push/call to emergency contacts
```

---

## Hardware & wiring (ESP8266 only)

### Components

* ESP8266 board (NodeMCU / Wemos D1 mini)
* Momentary push switch / micro‑switch (mounted so pressing spray toggles it)
* Small LiPo battery + charger (TP4056) or regulated 5V → 3.3V supply
* Wires, adhesive, enclosure

### Wiring (concept)

```
Push switch:
  One leg -> GND
  Other leg -> D1 (GPIO5)  (use INPUT_PULLUP in firmware)
Power:
  ESP8266 Vcc -> 3.3V
  GND -> common ground
```

> Tip: Use a small resistor if needed for debouncing, or handle debounce in software.

---

## ESP8266 firmware (alert-only example)

Save as `Esp_code_for_anzen.ino`. This code:

* watches a trigger pin,
* debounces it,
* pushes a tiny alert object to Firebase (deviceId + ts + short state),
* avoids storing secrets in repository (show placeholders).

```cpp
// Esp_code_for_anzen.ino
#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>

// ---------- CONFIG ----------
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

#define FIREBASE_HOST "YOUR_FIREBASE_PROJECT.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_DATABASE_SECRET" // use secure rules in prod

const uint8_t TRIGGER_PIN = D1; // GPIO5, switch to GND
const unsigned long DEBOUNCE_MS = 600; // prevent multiple triggers per spray
const char* DEVICE_ID = "nodeMCU-01";

// ---------- GLOBALS ----------
FirebaseData fbdo;
unsigned long lastTrigger = 0;

void setup() {
  Serial.begin(115200);
  pinMode(TRIGGER_PIN, INPUT_PULLUP); // active LOW
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print('.');
  }
  Serial.println("\nWiFi connected.");

  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);
}

void pushAlertToFirebase() {
  String path = "/alerts"; // firebase path where app listens
  String json = "{";
    json += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
    json += "\"ts\":" + String(millis()) + ",";
    json += "\"trigger\":true";
  json += "}";

  if (Firebase.pushJSON(fbdo, path, json)) {
    Serial.println("Alert pushed.");
  } else {
    Serial.println("Push failed: " + fbdo.errorReason());
  }
}

void loop() {
  // active LOW: pressed -> LOW
  if (digitalRead(TRIGGER_PIN) == LOW) {
    unsigned long now = millis();
    if (now - lastTrigger > DEBOUNCE_MS) {
      lastTrigger = now;
      Serial.println("Trigger detected! Sending alert...");
      pushAlertToFirebase();

      // blink onboard LED / indicator here if desired
    }
  }
  delay(50);
}
```

**Important**

* Replace `FIREBASE_AUTH` with secure server-side tokens or switch to Firebase Authentication + rules for production.
* Store secrets out of the repo (use OTA provisioning, config file excluded from git, or cloud provisioning).

---

## Firebase data model & recommended rules

### Example Realtime Database structure

```
/alerts/
  - <pushId1>:
      deviceId: "nodeMCU-01"
      ts: 169xxx...           # millis or server timestamp
      trigger: true
      processed: false        # set true by app/cloud after contacts notified
      location: {             # optional: appended by the app
         lat: 12.97,
         lng: 77.59,
         provider: "phone_gps",
         ts: 169xxx...
      }
```

### Recommended flow

1. ESP8266 `push` creates a new child under `/alerts`.
2. App listens for new children (or queries for `deviceId`) and, on receiving one, immediately:

   * Acquire phone GPS (FINE_LOCATION).
   * Update the alert node with `location` and `processedBy` info.
   * Send SMS/push/call to emergency contacts (directly from phone or via server).
   * Mark `processed: true` when done.
3. Optionally, a Cloud Function can be used to forward to Twilio or other services — keep secrets server-side.

### Recommended Firebase Rules (high level)

* Only authenticated users may read alerts for their `userId` or devices they are authorized to see.
* ESP device writes must be restricted to authenticated/whitelisted sources or validated by Cloud Function.
* Prevent public read/write on `/alerts` in production.

---

## Flutter app behavior (required)

The mobile app is the critical component here. It must:

### Permissions & setup

* Request and hold **foreground location permission** (FINE/GPS) — and optionally background if you want to get location when app is backgrounded. **Explain to the user why location is needed.**
* Request notification permission for push notifications.
* Store and manage `deviceId` ↔ `userId` pairing during device setup.

### Listener & immediate actions on alert

1. **Realtime listener:** App listens to `/alerts` (filter by `deviceId` or `userId`) for `trigger: true` children.
2. **On alert received:**

   * Immediately get the **current GPS location** from the phone (use best available — GPS preferred).
   * Update the same alert node with:

     ```json
     "location": { "lat": ..., "lng": ..., "provider": "phone_gps", "ts": 169... },
     "processedBy": "<userId>",
     "processedTs": 169...
     ```
   * Send notification/sms/call to emergency contacts. Options:

     * **Direct SMS from phone** using platform channel (Android `SmsManager`) or iOS alternatives (note: iOS limits programmatic SMS sending — you may open a prefilled SMS Composer and require user confirmation).
     * **Push + Call:** Use intent to open dialer with contact number prefilled.
     * **Server-side SMS:** App calls a secure Cloud Function endpoint which sends SMS via Twilio (recommended for reliability and for iOS limitations).
3. **UI:** Show full-screen alert screen (siren sound, big STOP button to cancel and mark `resolved`) and a map centered on the phone location with a share button.

### Fault handling

* If phone cannot get a GPS fix quickly, send best-effort coarse location and update when a better fix is available.
* Allow user to cancel false alerts (will update `resolved: true` and optionally write a `cancelledBy` field).
* Implement retry logic for write/update failures.

---

## Security, privacy & best practices

* **Do not commit secrets.** Keep `FIREBASE_AUTH` and other keys out of repo. Use environment variables, encrypted config, or Firebase Auth + Cloud Functions.
* **User consent & transparency.** Clearly show why location is collected and how it's used. Keep a privacy policy.
* **Minimize stored data.** Remove alerts older than a TTL (e.g., 30 days) or move them to an archive with restricted access.
* **Authentication & rules.** Use Firebase Authentication and strict database rules so only authorized users/devices can read/write their alerts.
* **Rate limiting & debouncing.** On device and app level to prevent spam/accidental multiple alerts.
* **Tamper‑detection.** Add a deviceId and verify device ownership in app pairing flow.

---

## Testing & deployment checklist

* [ ] Replace placeholder Wi‑Fi and Firebase credentials with test credentials (not production secrets).
* [ ] Test trigger push while app is foreground, background, and killed (note behavior differs by OS).
* [ ] Test location acquisition timeouts — ensure app updates location when it becomes available.
* [ ] Verify SMS/push behavior on both Android and iOS (iOS restrictions apply).
* [ ] Validate Firebase Rules with security analyzer and manual tests.
* [ ] Test false-positive cancellation flow.
* [ ] Provide user manual for physical mounting and safe use.

---

## Contributing

1. Fork the repository.
2. Create a branch: `git checkout -b feat/your-feature`.
3. Implement changes and add tests.
4. Open a Pull Request with description and testing steps.

For changes involving auth or cloud functions, include a brief security review in the PR.

---

## License

MIT. See `LICENSE` file.

---




Which of the two would you like next?
