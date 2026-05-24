#include <ESP32Servo.h>

const int servoPin = 4;
Servo servo;

void setup() {
  Serial.begin(115200);
  
  // Configuration pour ESP32
  ESP32PWM::allocateTimer(1);
  servo.setPeriodHertz(50);
  servo.attach(servoPin);
  
  Serial.println("--- Test Servomoteur démarré ---");
}

void loop() {
  Serial.println("Angle: 90 degrés (Centre)");
  servo.write(90);
  delay(1500);

  Serial.println("Angle: 45 degrés (Gauche)");
  servo.write(45);
  delay(1500);
  
  Serial.println("Angle: 90 degrés (Centre)");
  servo.write(90);
  delay(1500);

  Serial.println("Angle: 135 degrés (Droite)");
  servo.write(135);
  delay(1500);
}
