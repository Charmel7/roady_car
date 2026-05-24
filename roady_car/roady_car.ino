#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <MPU6050.h>
#include <Wire.h>
#include <ESP32Servo.h>

// =========================================================
// BROCHES 
// =========================================================
const int trig      = 18;
const int echo      = 19;
const int servoPin  = 4;
const int IN1       = 13;
const int IN2       = 12;
const int ENA       = 14;
const int IN3       = 27;
const int IN4       = 26;
const int ENB       = 25;
const int buzzerPin = 33;

// =========================================================
// CONSTANTES
// =========================================================
const int   DISTANCE_SECURITE   = 20;     // cm
const float MPU_SENSITIVITY     = 131.0f;
const int   ACCEL_STEP          = 10;
const int   DECEL_STEP          = 20;
const int   SPEED_UPDATE_MS     = 50;
const int   BLE_SEND_MS         = 100;    // 10 Hz pour désengorger le Bluetooth
const int   SERVO_SETTLE_MS     = 300;
const int   DISTANCE_UPDATE_MS  = 60;     // ~16 Hz max pour ultrason
const int   TIME_90DEG_MS       = 90;     // durée virage ~90°

// Canaux LEDC (PWM natif ESP32)
const int LEDC_CH_A = 0;
const int LEDC_CH_B = 1;
const int LEDC_FREQ = 5000;
const int LEDC_RES  = 8;   // 8 bits → 0-255

// =========================================================
// OBJETS
// =========================================================
Servo   servo;
MPU6050 mpu;

// =========================================================
// FLAGS VOLATILS (partagés BLE thread / loop thread)
// =========================================================
volatile bool autoMode       = false;
volatile bool priorityStop   = false;

// =========================================================
// VITESSE
// =========================================================
int           currentSpeed   = 0;
int           targetSpeed    = 0;
unsigned long lastSpeedUpdate = 0;

// =========================================================
// TIMER RECULER — non-bloquant, flag séparé
// =========================================================
volatile bool reculerActive   = false;
unsigned long reculerStart    = 0;
int           reculerDuration = 0;

// =========================================================
// TIMER TOURNER — non-bloquant, flag séparé (FIX #1)
// =========================================================
volatile bool tournerActive   = false;
unsigned long tournerStart    = 0;

// =========================================================
// DISTANCE CACHE — lecture limitée à ~16 Hz (FIX #3)
// =========================================================
float         cachedDistance  = 999.0f;
unsigned long lastDistMeasure = 0;

// =========================================================
// BUZZER — machine d'états non-bloquante (FIX #4)
// =========================================================
enum BuzzerState { BUZ_IDLE, BUZ_BEEP1, BUZ_PAUSE1, BUZ_BEEP2, BUZ_PAUSE2, BUZ_BEEP3 };
BuzzerState   buzState        = BUZ_IDLE;
unsigned long buzTimer        = 0;

// =========================================================
// SCRUTER — machine d'états non-bloquante
// =========================================================
enum ScruterState { SC_IDLE, SC_LEFT, SC_RIGHT, SC_CENTER, SC_DONE };
ScruterState  scruterState  = SC_IDLE;
unsigned long scruterTimer  = 0;
float         distGauche    = 0.0f;
float         distDroite    = 0.0f;

// =========================================================
// MODE AUTO — machine d'états
// =========================================================
enum AutoState { AUTO_AVANCE, AUTO_RECULE, AUTO_SCRUTE, AUTO_TOURNE };
AutoState autoState = AUTO_AVANCE;

// =========================================================
// BLE
// =========================================================
#define SERVICE_UUID           "FFE0"
#define CHARACTERISTIC_UUID_RX "FFE1"
#define CHARACTERISTIC_UUID_TX "FFE2"
#define BLE_DEVICE_NAME        "SMARTCAR"

BLEServer         *pServer           = nullptr;
BLECharacteristic *pTxCharacteristic = nullptr;
bool deviceConnected    = false;
bool oldDeviceConnected = false;
unsigned long lastBLESend = 0;

// =========================================================
// PROTOTYPES
// =========================================================
void  setupPWM();
void  setupServo();
void  setupMPU();
void  setupBLE();
void  setTargetSpeed(int speed);
void  updateSpeed();
void  avancer();
void  reculer(int temps);
void  checkReculer();
void  tournerGauche();
void  tournerDroite();
void  checkTourner();
void  arreter();
float getRawDistance();
float getCachedDistance();
void  scruterUpdate();
int   getScruterResult();
void  runAutoMode();
void  sendBLEData();
void  notifyBLE(const char* msg);
void  jouerSon(char type);
void  updateBuzzer();

// =========================================================
// CALLBACKS BLE
// =========================================================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    deviceConnected = true;
    BLEDevice::startAdvertising();
    Serial.println("[BLE] Connecté");
  }
  void onDisconnect(BLEServer* srv) override {
    deviceConnected = false;
    priorityStop = true;
    arreter();
    priorityStop = false;
    reculerActive  = false;
    tournerActive  = false;
    Serial.println("[BLE] Déconnecté");
    delay(500);
    srv->startAdvertising();
  }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pChar) override {
    String value = pChar->getValue().c_str();
    if (value.length() == 0) return;

    char   command = value[0];
    String param   = value.substring(1);

    // --- Arrêt d'urgence (FIX bug || / &&) ---
    if (command == 'E' || (command == 'S' && param == "0")) {
      priorityStop  = true;
      autoMode      = false;
      reculerActive = false;
      tournerActive = false;
      scruterState  = SC_IDLE;
      autoState     = AUTO_AVANCE;
      setTargetSpeed(0);
      arreter();
      priorityStop = false;
      Serial.println("[CMD] STOP D'URGENCE");
      return;
    }

    if (priorityStop) return;

    switch (command) {

      case 'M':
        if (value.length() >= 2) {
          bool newMode = (value[1] == 'A');
          if (!newMode && autoMode) {
            // Sortie du mode auto : tout réinitialiser
            reculerActive = false;
            tournerActive = false;
            scruterState  = SC_IDLE;
            autoState     = AUTO_AVANCE;
            setTargetSpeed(0);
            arreter();
          }
          autoMode = newMode;
          Serial.printf("[CMD] Mode: %s\n", autoMode ? "AUTO" : "MANUEL");
        }
        break;

      case 'S':
        if (param.length() > 0) {
          setTargetSpeed(param.toInt());
          Serial.printf("[CMD] Vitesse: %d\n", targetSpeed);
        }
        break;

      case 'F':
        if (!autoMode) { avancer(); Serial.println("[CMD] Avance"); }
        else notifyBLE("WARN:AutoMode");
        break;

      case 'B':
        if (!autoMode) {
          reculer(param.length() > 0 ? param.toInt() : 300);
          Serial.println("[CMD] Recule");
        } else notifyBLE("WARN:AutoMode");
        break;

      case 'L':
        if (!autoMode) { tournerGauche(); Serial.println("[CMD] Gauche"); }
        else notifyBLE("WARN:AutoMode");
        break;

      case 'R':
        if (!autoMode) { tournerDroite(); Serial.println("[CMD] Droite"); }
        else notifyBLE("WARN:AutoMode");
        break;

      case 'H':
        if (value.length() >= 2) jouerSon(value[1]);
        break;

      default:
        Serial.printf("[WARN] Commande inconnue: %c\n", command);
        break;
    }
  }
};

// =========================================================
// SETUP
// =========================================================
void setup() {
  Serial.begin(115200);
  Wire.begin();

  setupPWM();
  setupServo();

  pinMode(IN1,       OUTPUT);
  pinMode(IN2,       OUTPUT);
  pinMode(IN3,       OUTPUT);
  pinMode(IN4,       OUTPUT);
  pinMode(trig,      OUTPUT);
  pinMode(echo,      INPUT);
  pinMode(buzzerPin, OUTPUT);

  arreter();
  jouerSon('1');

  setupMPU();
  setupBLE();

  Serial.println("[INIT] SmartCar v3 prêt !");
}

// =========================================================
// LOOP
// =========================================================
void loop() {
  // Reconnexion BLE
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = false;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = true;
  }

  updateSpeed();       // Rampe accélération/décélération
  checkReculer();      // Fin de recul non-bloquant
  checkTourner();      // Fin de virage non-bloquant (FIX #1)
  updateBuzzer();      // Bips non-bloquants (FIX #4)
  sendBLEData();       // Envoi gyro/vitesse

  if (autoMode && !priorityStop) {
    runAutoMode();
  }
}

// =========================================================
// SETUP HELPERS
// =========================================================
void setupPWM() {
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  analogWrite(ENA, 0);  // moteur A arrêté
  analogWrite(ENB, 0);  // moteur B arrêté
}


void setupServo() {
  ESP32PWM::allocateTimer(1);
  servo.setPeriodHertz(50);
  servo.attach(servoPin);
  Serial.println("[SERVO] Initialisation à 90 degrés");
  servo.write(90);
}

void setupMPU() {
  mpu.initialize();
  mpu.CalibrateGyro(6);
  if (!mpu.testConnection()) {
    Serial.println("[ERREUR] MPU6050 non détecté !");
    while (1) delay(1000);
  }
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_250);
  mpu.setDLPFMode(MPU6050_DLPF_BW_42);
  Serial.println("[INIT] MPU6050 OK");
}

void setupBLE() {
  BLEDevice::init(BLE_DEVICE_NAME);
  BLEDevice::setPower(ESP_PWR_LVL_P9);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pTxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxChar = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
  pRxChar->setCallbacks(new MyCallbacks());

  pService->start();

  BLEAdvertising *pAdv = BLEDevice::getAdvertising();
  pAdv->addServiceUUID(SERVICE_UUID);
  pAdv->setScanResponse(true);
  pAdv->setMinInterval(32);
  pAdv->setMaxInterval(64);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Advertising démarré...");
}

// =========================================================
// BLE — Envoi données gyro + vitesse
// =========================================================
void sendBLEData() {
  if (!deviceConnected) return;
  if (millis() - lastBLESend < BLE_SEND_MS) return;
  lastBLESend = millis();

  int16_t gx_raw, gy_raw, gz_raw;
  mpu.getRotation(&gx_raw, &gy_raw, &gz_raw);

  // Conversion et deadband (filtre anti-bruit au repos)
  float gx = gx_raw / MPU_SENSITIVITY;
  float gy = gy_raw / MPU_SENSITIVITY;
  float gz = gz_raw / MPU_SENSITIVITY;
  
  if (abs(gx) < 0.5) gx = 0.0;
  if (abs(gy) < 0.5) gy = 0.0;
  if (abs(gz) < 0.5) gz = 0.0;

  char txData[50];
  int written = snprintf(txData, sizeof(txData),
    "T:%d,%.2f,%.2f,%.2f\n",
    currentSpeed,
    gx,
    gy,
    gz
  );

  if (written > 0 && written < (int)sizeof(txData)) {
    pTxCharacteristic->setValue(txData);
    pTxCharacteristic->notify();
  } else {
    Serial.println("[WARN] Erreur format BLE TX");
  }
}

void notifyBLE(const char* msg) {
  if (!deviceConnected || !pTxCharacteristic) return;
  char buf[40];
  snprintf(buf, sizeof(buf), "%s\n", msg);
  pTxCharacteristic->setValue(buf);
  pTxCharacteristic->notify();
}

// =========================================================
// VITESSE — rampe non-bloquante
// =========================================================
void setTargetSpeed(int speed) {
  targetSpeed = constrain(speed, 0, 255);
}

void updateSpeed() {
  if (millis() - lastSpeedUpdate < SPEED_UPDATE_MS) return;
  lastSpeedUpdate = millis();

  if (currentSpeed < targetSpeed)
    currentSpeed = min(currentSpeed + ACCEL_STEP, targetSpeed);
  else if (currentSpeed > targetSpeed)
    currentSpeed = max(currentSpeed - DECEL_STEP, targetSpeed);

analogWrite(ENA, currentSpeed);
analogWrite(ENB, currentSpeed);

}

// =========================================================
// MOUVEMENTS
// =========================================================
void avancer() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}

// --- Reculer non-bloquant ---
void reculer(int temps) {
  digitalWrite(IN1, LOW);  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW);  digitalWrite(IN4, HIGH);
  reculerStart    = millis();
  reculerDuration = temps;
  reculerActive   = true;
}

void checkReculer() {
  if (!reculerActive) return;
  if (millis() - reculerStart >= (unsigned long)reculerDuration) {
    arreter();
    reculerActive = false;
    Serial.println("[MOT] Fin recul");
  }
}

// --- Tourner non-bloquant — flag séparé de reculer (FIX #1) ---
void tournerGauche() {
  if (tournerActive) return; // Virage déjà en cours
  digitalWrite(IN1, LOW);  digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
  tournerStart  = millis();
  tournerActive = true;
}

void tournerDroite() {
  if (tournerActive) return;
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);  digitalWrite(IN4, HIGH);
  tournerStart  = millis();
  tournerActive = true;
}

void checkTourner() {
  if (!tournerActive) return;
  if (millis() - tournerStart >= TIME_90DEG_MS) {
    arreter();
    tournerActive = false;
    Serial.println("[MOT] Fin virage");
  }
}

void arreter() {
  targetSpeed  = 0;
  currentSpeed = 0;
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);

  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}

// =========================================================
// DISTANCE — lecture limitée ~16 Hz (FIX #3)
// =========================================================
float getRawDistance() {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  long dur = pulseIn(echo, HIGH, 25000);
  if (dur == 0) {
    Serial.println("[ULTRASON] Distance: 999.0 cm (Timeout)");
    return 999.0f; // Timeout → pas d'obstacle
  }
  float dist = dur * 0.034f / 2.0f;
  Serial.printf("[ULTRASON] Distance: %.1f cm\n", dist);
  return dist;
}

float getCachedDistance() {
  if (millis() - lastDistMeasure >= DISTANCE_UPDATE_MS) {
    cachedDistance  = getRawDistance();
    lastDistMeasure = millis();
  }
  return cachedDistance;
}

// =========================================================
// SCRUTER — machine d'états non-bloquante
// =========================================================
void scruterUpdate() {
  switch (scruterState) {
    case SC_IDLE:
      Serial.println("[SERVO] Déplacement à 45 degrés (Gauche)");
      servo.write(45);
      scruterTimer = millis();
      scruterState = SC_LEFT;
      break;

    case SC_LEFT:
      if (millis() - scruterTimer >= SERVO_SETTLE_MS) {
        distGauche   = getRawDistance();
        Serial.println("[SERVO] Déplacement à 135 degrés (Droite)");
        servo.write(135);
        scruterTimer = millis();
        scruterState = SC_RIGHT;
      }
      break;

    case SC_RIGHT:
      if (millis() - scruterTimer >= SERVO_SETTLE_MS) {
        distDroite   = getRawDistance();
        Serial.println("[SERVO] Retour à 90 degrés (Centre)");
        servo.write(90);
        scruterTimer = millis();
        scruterState = SC_CENTER;
      }
      break;

    case SC_CENTER:
      if (millis() - scruterTimer >= SERVO_SETTLE_MS) {
        scruterState = SC_DONE;
        Serial.printf("[SCRUT] G:%.1f D:%.1f\n", distGauche, distDroite);
      }
      break;

    case SC_DONE:
      break; // Résultat disponible via getScruterResult()
  }
  
}

int getScruterResult() {
  if (fabsf(distDroite - distGauche) < 5.0f) return 0; // Neutre
  return (distDroite > distGauche) ? 1 : -1;
}

// =========================================================
// MODE AUTO — machine d'états non-bloquante (FIX #2)
// =========================================================
void runAutoMode() {
  // Ne rien faire pendant un recul ou un virage en cours
  if (reculerActive || tournerActive) return;

  switch (autoState) {

    case AUTO_AVANCE: {
      float dist = getCachedDistance(); // FIX #3 : lecture limitée
      if (dist > DISTANCE_SECURITE) {
        notifyBLE("D:0"); // Vert: pas d'obstacle
        setTargetSpeed(150);
        avancer();
      } else {
        notifyBLE("D:1"); // Rouge: obstacle détecté
        Serial.println("[AUTO] Obstacle ! Recul...");
        setTargetSpeed(100);
        reculer(300);          // Non-bloquant
        autoState = AUTO_RECULE;
      }
      break;
    }

    case AUTO_RECULE:
      // checkReculer() gère la fin ; on attend ici (FIX #2 : guard au-dessus)
      if (!reculerActive) {
        scruterState = SC_IDLE;
        autoState    = AUTO_SCRUTE;
        Serial.println("[AUTO] Recul terminé, scrute...");
      }
      break;

    case AUTO_SCRUTE:
      scruterUpdate();
      if (scruterState == SC_DONE) {
        autoState = AUTO_TOURNE;
      }
      break;

    case AUTO_TOURNE:
      // Lancer le virage (non-bloquant), guard en haut du switch arrêtera
      // le prochain tick tant que tournerActive == true (FIX #2)
      if (!tournerActive) {
        int dir = getScruterResult();
        if      (dir == 1)  { setTargetSpeed(150); tournerDroite(); }
        else if (dir == -1) { setTargetSpeed(150); tournerGauche(); }
        else                { arreter(); autoState = AUTO_AVANCE; break; }
        // autoState ne passe à AUTO_AVANCE qu'après fin du virage
        autoState = AUTO_AVANCE;
      }
      break;
  }
}

// =========================================================
// BUZZER — machine d'états non-bloquante (FIX #4)
// Triple bip sans aucun delay()
// =========================================================
void updateBuzzer() {
  if (buzState == BUZ_IDLE) return;
  unsigned long now = millis();

  switch (buzState) {
    case BUZ_BEEP1:
      if (now - buzTimer >= 100) { noTone(buzzerPin); buzTimer = now; buzState = BUZ_PAUSE1; }
      break;
    case BUZ_PAUSE1:
      if (now - buzTimer >= 100) { tone(buzzerPin, 1000); buzTimer = now; buzState = BUZ_BEEP2; }
      break;
    case BUZ_BEEP2:
      if (now - buzTimer >= 100) { noTone(buzzerPin); buzTimer = now; buzState = BUZ_PAUSE2; }
      break;
    case BUZ_PAUSE2:
      if (now - buzTimer >= 100) { tone(buzzerPin, 1000); buzTimer = now; buzState = BUZ_BEEP3; }
      break;
    case BUZ_BEEP3:
      if (now - buzTimer >= 100) { noTone(buzzerPin); buzState = BUZ_IDLE; }
      break;
    default:
      break;
  }
}

void jouerSon(char type) {
  switch (type) {
    case '1': // Klaxon court — tone avec durée, non-bloquant
      tone(buzzerPin, 440, 300);
      break;

    case '2': // Triple bip — machine d'états (FIX #4)
      tone(buzzerPin, 1000);
      buzTimer = millis();
      buzState = BUZ_BEEP1;
      break;

    case '3': // Sirène — ponctuelle, delay accepté (usage rare)
      // Note : bloque ~1s. Pour usage fréquent, convertir en machine d'états.
      for (int i = 0; i < 2; i++) {
        for (int f = 500; f <= 1000; f += 10) { tone(buzzerPin, f); delay(5); }
        for (int f = 1000; f >= 500; f -= 10) { tone(buzzerPin, f); delay(5); }
      }
      noTone(buzzerPin);
      break;

    default:
      Serial.printf("[WARN] Son inconnu: %c\n", type);
      break;
  }
}
