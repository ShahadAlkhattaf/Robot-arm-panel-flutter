#include <Arduino.h>
#include <WiFiMulti.h>
#include <HTTPClient.h>
#include <WiFiClient.h>


// Serial debug output
#define DEBUG_SERIAL Serial

// WiFi network manager
WiFiMulti WiFiMulti;

// Server configuration
const char* serverHost = "IP address of your PC";
const String webPath = "/robot_arm_controlPanel"; // Web folder
const long pollInterval = 2000;                   // Check every 2 seconds

// Servo configuration
const int servoPins[6] = {14, 12, 13, 27, 26, 25};
Servo servos[6];

// Timing
unsigned long lastUpdate = 0;

// Setup
void setup() {
  DEBUG_SERIAL.begin(115200);

  // Visual boot countdown
  DEBUG_SERIAL.println();
  for (uint8_t t = 4; t > 0; t--) {
    DEBUG_SERIAL.printf("[BOOT] Starting in %d...\n", t);
    DEBUG_SERIAL.flush();
    delay(1000);
  }

  // Initialize WiFi in station mode
  WiFi.mode(WIFI_STA);

  // Add access points
  WiFiMulti.addAP("NETWORK_NAME", "PASSWORD");

  // Attach servos and set to neutral
  for (int i = 0; i < 6; i++) {
    servos[i].attach(servoPins[i]);
    servos[i].write(90);
    DEBUG_SERIAL.printf("[SERVO] %d attached to pin %d\n", i + 1, servoPins[i]);
  }

  DEBUG_SERIAL.println("[READY] Robot control system online.");
}

// Update server: set status = 0 
void setRobotIdle() {
  WiFiClient client;
  HTTPClient http;

  String url = "http://" + String(serverHost) + webPath + "/update_status.php";
  DEBUG_SERIAL.printf("[HTTP] Setting idle: %s\n", url.c_str());

  if (http.begin(client, url.c_str())) {
    int code = http.GET();
    if (code == 200) {
      DEBUG_SERIAL.println("[HTTP] Status updated to idle.");
    } else {
      DEBUG_SERIAL.printf("[HTTP] Update failed: %s\n", http.errorToString(code).c_str());
    }
    http.end();
  } else {
    DEBUG_SERIAL.println("[HTTP] Connection failed.");
  }
}

// Main Loop
void loop() {
  // Poll server at fixed interval
  if (millis() - lastUpdate >= pollInterval) {
    lastUpdate = millis();

    // Ensure WiFi is connected
    if (WiFiMulti.run() == WL_CONNECTED) {
      WiFiClient client;
      HTTPClient http;

      String url = "http://" + String(serverHost) + webPath + "/get_run_pose.php";
      DEBUG_SERIAL.println("[HTTP] Requesting current pose...");

      if (http.begin(client, url.c_str())) {
        int httpCode = http.GET();

        if (httpCode > 0) {
          DEBUG_SERIAL.printf("[HTTP] Response code: %d\n", httpCode);

          if (httpCode == 200) {
            String payload = http.getString();
            DEBUG_SERIAL.println("[DATA] " + payload);

            // Check if run command
            if (payload.startsWith("1")) {
              int angles[6];
              int index = 2;  
              int step = 0;

              while (step < 6 && index < (int)payload.length()) {
                int comma = payload.indexOf(',', index);
                if (comma == -1) comma = payload.length();

                String token = payload.substring(index, comma);
                index = comma + 1;

                // Extract angle from s1xx format
                String angleStr = token.substring(2);
                angles[step] = angleStr.toInt();
                angles[step] = max(0, min(180, angles[step]));

                DEBUG_SERIAL.printf("[MOVE] Servo %d → %d°\n", step + 1, angles[step]);
                step++;
              }

              // Execute motion
              for (int i = 0; i < 6; i++) {
                servos[i].write(angles[i]);
                delay(15);
              }

              // Notify completion
              setRobotIdle();
            }
          }
        } else {
          DEBUG_SERIAL.printf("[HTTP] Request failed: %s\n", http.errorToString(httpCode).c_str());
        }

        http.end();
      } else {
        DEBUG_SERIAL.println("[HTTP] Could not connect to server");
      }
    } else {
      DEBUG_SERIAL.println("[WIFI] Waiting for connection...");
    }
  }

  delay(100); // Small pause
}
