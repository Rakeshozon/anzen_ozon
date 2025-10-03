#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#define TRIGGER_PIN D8  
// WiFi credentials
#define WIFI_SSID "Airtel_rake_7744"
#define WIFI_PASSWORD "air97969"

// Firebase credentials
#define FIREBASE_HOST "anzenozon-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "vWWt197ntY4J3UbybIEKAWZuP0gOSaj8kaFbPxe2"

// Define Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

void setup() {
  Serial.begin(9600);
  pinMode(TRIGGER_PIN, INPUT_PULLUP); // D8 trigger, LOW = ALERT
  // Connect WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(" Connected!");

  // Setup Firebase config
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  float latitude = 12.97 + random(-100, 100) * 0.0001;
  float longitude = 77.59 + random(-100, 100) * 0.0001;
  String status;
if (digitalRead(TRIGGER_PIN) == HIGH) {
    status = "ALERT";
  } else {
    status = "SAFE";
  }
  if (Firebase.setFloat(fbdo, "/test/latitude", latitude)) {
    Serial.println("Latitude updated: " + String(latitude));
  } else {
    Serial.println("Error: " + fbdo.errorReason());
  }

  if (Firebase.setFloat(fbdo, "/test/longitude", longitude)) {
    Serial.println("Longitude updated: " + String(longitude));
  } else {
    Serial.println("Error: " + fbdo.errorReason());
  }

  if (Firebase.setString(fbdo, "/test/status", status)) {
    Serial.println("Status updated: " + status);
  } else {
    Serial.println("Error: " + fbdo.errorReason());
  }

  delay(5000); // every 5 sec
}

