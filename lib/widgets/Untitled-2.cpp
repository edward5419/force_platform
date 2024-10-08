#include <ADS1220_WE.h>
#include <SPI.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define ADS1220_CS_PIN 5 // chip select pin
#define ADS1220_DRDY_PIN 26 // data ready pin
const int LED_PIN = 16; // LED 핀 번호
bool ledState = true;

// BLE 서버 객체를 가리키는 포인터
BLEServer* pServer = NULL;

// BLE 특성 객체를 가리키는 포인터
BLECharacteristic* pCharacteristic = NULL;
BLECharacteristic* pCharacteristic2 = NULL;

// 장치 연결 상태를 나타내는 변수
bool deviceConnected = false;
bool oldDeviceConnected = false;

// 데이터 전송 간격 관리 변수
unsigned long previousMillis = 0;
const long interval = 20; // 데이터 전송 간격 (밀리초)

// 서비스 및 특성 UUID 정의
#define SERVICE_UUID "0000180A-0000-1000-8000-00805F9B34FB"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_UUID2 "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// 칼만 필터 변수
float kalman_gain1 = 0.5;
float kalman_gain2 = 0.5;
float estimate1 = 0;
float estimate2 = 0;
float error_estimate1 = 0.1; // 초기 추정 오차 감소
float error_estimate2 = 0.1; // 초기 추정 오차 감소
float error_measure = 1.0; // 측정 오차 증가

// 평균 계산을 위한 변수
const int numReadings = 100; // 평균을 계산할 샘플 수
long readings1[numReadings];
long readings2[numReadings];
int readIndex = 0;
long total1 = 0;
long total2 = 0;

ADS1220_WE ads = ADS1220_WE(ADS1220_CS_PIN, ADS1220_DRDY_PIN);

// BLE 서버 콜백 클래스 정의
class MyServerCallbacks: public BLEServerCallbacks {
void onConnect(BLEServer* pServer) override {
deviceConnected = true;
};


복사
void onDisconnect(BLEServer* pServer) override {
  deviceConnected = false;
}
};

float convertADC1toKg(long value) {
float kg = 1.0/1800.0*value-1700.0/1800.0;
if(kg<0){
kg = 0;
}
return kg;
}

float convertADC2toKg(long value) {
float kg = 1.0/1800.0*value-1900.0/1800.0;
if(kg<0){
kg = 0;
}
return kg;
}

void setup(){
pinMode(15, OUTPUT);
Serial.begin(115200);
if(!ads.init()){
Serial.println("ADS1220 is not connected!");
while(1);
}

ads.init();
ads.setDataRate(ADS1220_DR_LVL_6);
ads.setConversionMode(ADS1220_SINGLE_SHOT);
ads.setOperatingMode(ADS1220_TURBO_MODE);
ads.setFIRFilter(ADS1220_50HZ_60HZ);
ads.bypassPGA(true);
ads.setSPIClockSpeed(4000000);
ads.start();

// BLE 초기화
BLEDevice::init("ESP32_BLE_Device");
pServer = BLEDevice::createServer();
pServer->setCallbacks(new MyServerCallbacks());
BLEService *pService = pServer->createService(SERVICE_UUID);

pCharacteristic = pService->createCharacteristic(
CHARACTERISTIC_UUID,
BLECharacteristic::PROPERTY_READ |
BLECharacteristic::PROPERTY_WRITE |
BLECharacteristic::PROPERTY_NOTIFY
);
pCharacteristic->addDescriptor(new BLE2902());

pCharacteristic2 = pService->createCharacteristic(
CHARACTERISTIC_UUID2,
BLECharacteristic::PROPERTY_READ |
BLECharacteristic::PROPERTY_WRITE |
BLECharacteristic::PROPERTY_NOTIFY
);
pCharacteristic2->addDescriptor(new BLE2902());

pService->start();
BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
pAdvertising->addServiceUUID(SERVICE_UUID);
pAdvertising->setScanResponse(false);
pAdvertising->setMinPreferred(0x0);
BLEDevice::startAdvertising();
Serial.println("BLE 장치가 광고를 시작했습니다.");

// 평균 계산을 위한 배열 초기화
for (int i = 0; i < numReadings; i++) {
readings1[i] = 0;
readings2[i] = 0;
}
}

// 칼만 필터 함수
float kalmanFilter(float measurement, float &estimate, float &error_estimate, float &kalman_gain) {
float error_estimate_temp = error_estimate + 0.001; // 프로세스 노이즈 감소
kalman_gain = error_estimate_temp / (error_estimate_temp + error_measure);
estimate = estimate + kalman_gain * (measurement - estimate);
error_estimate = (1 - kalman_gain) * error_estimate_temp;
return estimate;
}

int printCnt = 0;
void loop() {
ads.setCompareChannels(ADS1220_MUX_0_1);
long rawResult1 = ads.getRawData();

ads.setCompareChannels(ADS1220_MUX_2_3);
long rawResult2 = ads.getRawData();

// 평균 계산
total1 = total1 - readings1[readIndex];
total2 = total2 - readings2[readIndex];
readings1[readIndex] = rawResult1;
readings2[readIndex] = rawResult2;
total1 = total1 + readings1[readIndex];
total2 = total2 + readings2[readIndex];
readIndex = (readIndex + 1) % numReadings;

long average1 = total1 / numReadings;
long average2 = total2 / numReadings;

// 칼만 필터 적용
float filtered1 = kalmanFilter(average1, estimate1, error_estimate1, kalman_gain1);
float filtered2 = kalmanFilter(average2, estimate2, error_estimate2, kalman_gain2);

// 필터링된 값을 KG으로 변환
float weight1 = convertADC1toKg(filtered1);
float weight2 = convertADC2toKg(filtered2);

// BLE를 통한 데이터 전송
if (deviceConnected) {
unsigned long currentMillis = millis();
if (currentMillis - previousMillis >= interval) {
previousMillis = currentMillis;

ini

복사
  if(printCnt>30){
    Serial.println();
    printCnt = 0;
  }
  Serial.print(weight1, 2);
  Serial.print(" ");
  printCnt++;
  
  String dataString1 = String(weight1, 2);
  String dataString2 = String(weight2, 2);
  
  pCharacteristic->setValue(dataString1.c_str());
  pCharacteristic->notify();
  pCharacteristic2->setValue(dataString2.c_str());
  pCharacteristic2->notify();
}
}

// 연결 상태 변경 처리
if (!deviceConnected && oldDeviceConnected) {
delay(500);
pServer->startAdvertising();
Serial.println("start advertising");
oldDeviceConnected = deviceConnected;
}
if (deviceConnected && !oldDeviceConnected) {
oldDeviceConnected = deviceConnected;
}
}