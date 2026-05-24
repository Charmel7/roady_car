const int trig = 18;
const int echo = 19;

void setup() {
  Serial.begin(115200);
  pinMode(trig, OUTPUT);
  pinMode(echo, INPUT);
  Serial.println("--- Test Capteur Ultrason démarré ---");
}

void loop() {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  
  // Envoi d'une impulsion de 10 microsecondes sur trig
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  
  // Mesure du temps de l'écho
  long dur = pulseIn(echo, HIGH, 25000); // timeout à 25ms
  
  if (dur == 0) {
    Serial.println("Distance: Hors de portée ou timeout");
  } else {
    // Calcul de la distance en cm
    float dist = dur * 0.034f / 2.0f;
    Serial.printf("Distance: %.1f cm\n", dist);
  }
  
  // Pause de 500ms entre deux mesures pour faciliter la lecture
  delay(500);
}
