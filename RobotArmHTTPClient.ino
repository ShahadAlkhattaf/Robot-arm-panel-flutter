#include <Arduino.h>
#include <WiFiMulti.h>
#include <HTTPClient.h>
#include <WiFiClient.h>
#include <Servo.h>

WiFiMulti WiFiMulti;

const char* serverHost = "Replace with your PC IP";
const String webPath = "/robot_arm_controlPanel";
const long pollInterval = 2000;

const int servoPins[4] = {14, 12, 13, 27};
Servo servos[4];

unsigned long lastUpdate = 0;

void setup() {
  Serial.begin(115200);
  WiFiMulti.addAP("NETWORK_NAME", "PASSWORD"); 
  for (int i = 0; i < 4; i++) {
    servos[i].attach(servoPins[i]);
    servos[i].write(90);
  }
}

void setRobotIdle() {
  WiFiClient client;
  HTTPClient http;

  String url = "http://" + String(serverHost) + webPath + "/update_status.php";
  if (http.begin(client, url.c_str())) {
    int code = http.GET();
    http.end();
  }
}

void loop() {
  if (millis() - lastUpdate >= pollInterval) {
    lastUpdate = millis();

    if (WiFiMulti.run() == WL_CONNECTED) {
      WiFiClient client;
      HTTPClient http;

      String url = "http://" + String(serverHost) + webPath + "/get_run_pose.php";
      if (http.begin(client, url.c_str())) {
        int httpCode = http.GET();
        if (httpCode == 200) {
          String payload = http.getString();

          if (payload.startsWith("1")) {
            int angles[4];
            int index = 2;
            int step = 0;

            while (step < 4 && index < (int)payload.length()) {
              int comma = payload.indexOf(',', index);
              if (comma == -1) comma = payload.length();

              String token = payload.substring(index, comma);
              index = comma + 1;

              String angleStr = token.substring(2);
              angles[step] = angleStr.toInt();
              angles[step] = max(0, min(180, angles[step]));

              step++;
            }

            for (int i = 0; i < 4; i++) {
              servos[i].write(angles[i]);
              delay(15);
            }

            setRobotIdle();
          }
        }
        http.end();
      }
    }
  }
}

