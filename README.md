

# Anzen Ozon

**Anzen Ozon** is a multi-platform system designed for **real-time ozone monitoring and control**, integrating **Flutter mobile and desktop applications** with **ESP8266-based IoT devices**. It allows users to **monitor ozone levels**, **trigger alerts**, and **log environmental data** for analysis.

This project combines **mobile, desktop, and IoT technologies**, making it an end-to-end solution for ozone level management in homes, offices, or industrial environments.

---

## Table of Contents

* [Features](#features)
* [Project Structure](#project-structure)
* [Requirements](#requirements)
* [Installation](#installation)
* [ESP8266 Firmware Setup](#esp8266-firmware-setup)
* [Usage](#usage)
* [Firebase & Data Flow](#firebase--data-flow)
* [Testing](#testing)
* [Screenshots](#screenshots)
* [Contributing](#contributing)
* [License](#license)

---

## Features

* **Cross-Platform Flutter App**

  * Supports **Android**, **iOS**, **Windows**, **macOS**, and **Linux**
  * Unified UI across platforms
* **Real-Time Monitoring**

  * Connects to **ESP8266 sensors** for ozone level detection
  * Data updates live in the app
* **Alerts and Notifications**

  * Push notifications for high ozone levels
  * Optional SMS integration for urgent alerts
* **Data Logging**

  * Logs ozone levels locally and/or in a cloud database
  * Supports exporting logs for analysis
* **IoT Integration**

  * ESP8266 firmware handles **sensor readings**, **data transmission**, and **actuator control**
* **Testing Framework**

  * Flutter unit and widget tests included

---

## Project Structure

```text
anzen_ozon/
├── android/           # Android app source code
├── ios/               # iOS app source code
├── lib/               # Shared Flutter code
├── linux/             # Linux desktop app source code
├── macos/             # macOS desktop app source code
├── windows/           # Windows desktop app source code
├── assets/
│   └── images/        # App images and icons
├── test/              # Unit and widget tests
├── Esp_code_for_anzen.ino  # ESP8266 Arduino code for sensors and IoT integration
└── README.md          # Project documentation
```

---

## Requirements

### Software

* **Flutter** (>=3.0)
* **Dart SDK**
* **Arduino IDE** (for ESP8266 firmware upload)
* Platform-specific dependencies for Windows/macOS/Linux builds

### Hardware

* **ESP8266 microcontroller**
* **Ozone sensor module**
* Optional: GSM module for SMS alerts

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Rakeshozon/anzen_ozon.git
cd anzen_ozon
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run Flutter App

* **Mobile (Android/iOS):**

```bash
flutter run
```

* **Desktop (Windows/macOS/Linux):**

```bash
flutter run -d windows   # or macos/linux
```

---

## ESP8266 Firmware Setup

1. Open `Esp_code_for_anzen.ino` in the **Arduino IDE**
2. Install the **ESP8266 board package** via Tools → Board → Boards Manager
3. Configure **Wi-Fi credentials**, **Firebase URL**, and **sensor pins**
4. Select **ESP8266 board** under Tools → Board → NodeMCU/Generic ESP8266
5. Upload the code to the ESP8266

```cpp
#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>

// Wi-Fi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase credentials
#define FIREBASE_HOST "YOUR_FIREBASE_PROJECT.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_DATABASE_SECRET"

FirebaseData firebaseData;

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");

  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);
}

void loop() {
  float ozoneLevel = analogRead(A0) * (5.0 / 1023.0); // Example reading

  if (Firebase.setFloat(firebaseData, "/sensor/ozone", ozoneLevel)) {
    Serial.println("Ozone level uploaded successfully");
  } else {
    Serial.println("Firebase upload failed");
  }

  delay(5000); // Send data every 5 seconds
}
```

---

## Usage

* Open the **Anzen Ozon app** on your preferred platform
* Connect the app to your **ESP8266 device**
* Monitor ozone levels in **real-time**
* Set **alert thresholds** for notifications
* Export or analyze logged data if needed

---

## Firebase & Data Flow

The system integrates **ESP8266 sensors**, **Firebase Realtime Database**, and **Flutter app** to ensure real-time monitoring.

### Data Flow Overview

```text
+-----------------+        Wi-Fi        +-------------------------+
| ESP8266 Micro-  | --------------->   | Firebase Realtime DB    |
| controller +    |                     | (Stores sensor data)   |
| Ozone Sensor    |                     +-------------------------+
+-----------------+
          |
          | Bluetooth/Wi-Fi (optional)
          v
+-----------------+
| Flutter App     |
| (Mobile/Desktop)|
| - Reads Firebase|
| - Displays Data |
| - Sends Alerts  |
+-----------------+
```

### Step-by-Step Flow

1. **ESP8266 reads ozone levels** from the sensor at regular intervals
2. **ESP8266 sends data** to Firebase Realtime Database over Wi-Fi
3. **Flutter app listens** to Firebase for updates in real-time
4. **App displays data** via dashboards, graphs, and notifications
5. **Optional alert triggers** (SMS or push notifications) are fired if thresholds are crossed

---

## Testing

* **Unit Tests:** Located in `test/` folder
* Run tests using:

```bash
flutter test
```

* Tests cover **sensor data parsing**, **UI widgets**, and **alert triggers**

---

## Screenshots

*Add screenshots of the app and sensor dashboard here.*

```text
- assets/images/dashboard.png
- assets/images/alert.png
- assets/images/device_connect.png
```

---

## Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch:

```bash
git checkout -b feature-name
```

3. Commit your changes:

```bash
git commit -m "Add feature description"
```

4. Push and create a Pull Request

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---


