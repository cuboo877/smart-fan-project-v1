#include <ArduinoBLE.h>

// 定義服務和特徵的 UUID
// 確保這些 UUID 完全匹配

BLEService fanService("19B10000-E8F2-537E-4F6C-D104768A1214");
BLEStringCharacteristic fanCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLEWrite | BLERead, 20);
BLEStringCharacteristic notifyCharacteristic("19B10002-E8F2-537E-4F6C-D104768A1214", BLERead | BLENotify, 20);

bool isConnected = false;


const int fanPin = 17;   // 轉速偵測線連接的數位引腳
const int pwmPin = 16;    // PWM引腳

volatile int pulseCount = 0; // 計數變數
unsigned long lastTime = 0;   // 上一次計算時間
int pwm = 255;                // PWM值

void setup() {
  
  Serial.begin(9600);

  pinMode(pwmPin, OUTPUT);
  pinMode(fanPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(fanPin), countPulse, RISING);

  while (!Serial);

  // 初始化 BLE
  if (!BLE.begin()) {
    Serial.println("BLE 初始化失敗!");
    while (1);
  }

  // 設置廣播名稱
  BLE.setLocalName("Fan Control");
  BLE.setAdvertisedService(fanService);

  // 添加特徵到服務
  fanService.addCharacteristic(fanCharacteristic);
  fanService.addCharacteristic(notifyCharacteristic);

  // 添加服務
  BLE.addService(fanService);

  // 設置特徵的回調函數
  fanCharacteristic.setEventHandler(BLEWritten, fanCharacteristicWritten);

  // 開始廣播
  BLE.advertise();
  Serial.println("BLE Fan Control 已啟動");
  Serial.println("等待連接...");
}

void loop() {
  BLE.poll();

  // 檢查是否有中央設備連接
  checkBLEConnection();

  pwmControl();

  // 每3秒發送一次 HelloWorld
  static unsigned long lastTime = 0;
  if (millis() - lastTime >= 3000) {  // 每3秒執行一次
    if (isConnected) {
      notifyCharacteristic.writeValue("HelloWorld");
      Serial.println("已發送: HelloWorld");  // 用於調試
    }
    lastTime = millis();
  }
}

void pwmControl(){
  pwm = constrain(pwm, 0, 255);
  analogWrite(pwmPin, pwm); // 設定PWM值
  
}

void checkBLEConnection(){
  BLEDevice central = BLE.central();
  if (central) {
    if(isConnected == false){
      Serial.print("已連接到設備: ");
      Serial.println(central.address());
    }
    isConnected = true;
  }
}

void fanCharacteristicWritten(BLEDevice central, BLECharacteristic characteristic) {
  // 獲取接收到的命令
  String command = fanCharacteristic.value();
  
  Serial.print("收到命令: ");
  Serial.println(command);

  // 處理命令
  if (command == "SpeedUp") {
    Serial.println("增加風速");
    pwm += 51;
    Serial.print("PWM = ");
    Serial.println(pwm);
  } 
  else if (command == "SpeedDown") {
    Serial.println("降低風速");
    pwm -= 51;
    Serial.print("PWM = ");
    delay(20);
    Serial.println(pwm);
  }
  
}

void countPulse() {
    pulseCount++; // 每次脈衝加1
}