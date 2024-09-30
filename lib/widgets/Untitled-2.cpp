// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, sort_child_properties_last

#include <ADS1220_WE.h>
#include <SPI.h>
#include <BLEDevice.h> // BLEDevice 클래스 및 BLE 초기화 관련 함수 제공
#include <BLEServer.h> // BLEServer 클래스 및 서버 관련 함수 제공
#include <BLEUtils.h> // BLE 관련 유틸리티 함수 제공
#include <BLE2902.h> // BLE2902 디스크립터 클래스 제공

#define ADS1220_CS_PIN 5 // chip select pin
#define ADS1220_DRDY_PIN 26 // data ready pin
const int LED_PIN = 16; // LED 핀 번호
bool ledState = true;

// BLE 서버 객체를 가리키는 포인터 (BLEServer.h)
BLEServer* pServer = NULL;

// BLE 특성 객체를 가리키는 포인터 (BLEServer.h)
BLECharacteristic* pCharacteristic = NULL;
BLECharacteristic* pCharacteristic2 = NULL; // 두 번째 특성 포인터

// 장치 연결 상태를 나타내는 변수
bool deviceConnected = false;

// 이전 장치 연결 상태를 저장하는 변수
bool oldDeviceConnected = false;

// 데이터 전송 간격 관리 변수 (millis() 단위)
unsigned long previousMillis = 0;

// 데이터 전송 간격 설정 (밀리초)
const long interval = 1; // 예시로 50ms로 설정

// 서비스 및 특성 UUID 정의 (표준 Device Information Service UUID 사용)
#define SERVICE_UUID "0000180A-0000-1000-8000-00805F9B34FB" // Device Information Service UUID (0x180A)
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8" // 첫 번째 커스텀 Characteristic UUID
#define CHARACTERISTIC_UUID2 "beb5483e-36e1-4688-b7f5-ea07361b26a9" // 두 번째 커스텀 Characteristic UUID

// BLE 서버 콜백 클래스 정의 (BLEServerCallbacks 클래스 상속)
class MyServerCallbacks: public BLEServerCallbacks {
void onConnect(BLEServer* pServer) override {
deviceConnected = true;
};


복사
void onDisconnect(BLEServer* pServer) override {
  deviceConnected = false;
}
};

// 필터 변수 선언
long ema1 = 0; // 첫 번째 채널의 EMA 값
long ema2 = 0; // 두 번째 채널의 EMA 값
const int alpha = 20; // 평활화 계수 (0 < alpha < 100, 실제 값 = alpha / 100)
bool emaInitialized = false; // EMA 초기화 여부

ADS1220_WE ads = ADS1220_WE(ADS1220_CS_PIN, ADS1220_DRDY_PIN);

float convertADC1toKg(long ema) {

float kg = 1.0/1800.0*ema-1700.0/1800.0;
if(kg<0){
kg = 0;
}

return kg;
}

float convertADC2toKg(long ema) {
float kg = 1.0/1800.0*ema-1900.0/1800.0;
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
// ads.setGain(ADS1220_GAIN_4);
ads.setDataRate(ADS1220_DR_LVL_6);
ads.setConversionMode(ADS1220_SINGLE_SHOT);
ads.setOperatingMode(ADS1220_TURBO_MODE);
ads.setFIRFilter(ADS1220_50HZ_60HZ);
ads.bypassPGA(true);
ads.setSPIClockSpeed(4000000);
ads.start();

// BLE 초기화
BLEDevice::init("ESP32_BLE_Device"); // BLE 장치 이름 설정

// BLE 서버 생성
pServer = BLEDevice::createServer();
pServer->setCallbacks(new MyServerCallbacks());

// BLE 서비스 생성
BLEService *pService = pServer->createService(SERVICE_UUID);

// 첫 번째 BLE 특성 생성 및 속성 설정
pCharacteristic = pService->createCharacteristic(
CHARACTERISTIC_UUID,
BLECharacteristic::PROPERTY_READ |
BLECharacteristic::PROPERTY_WRITE |
BLECharacteristic::PROPERTY_NOTIFY
);

// BLE 특성에 BLE2902 디스크립터 추가
pCharacteristic->addDescriptor(new BLE2902());

// 두 번째 BLE 특성 생성 및 속성 설정
pCharacteristic2 = pService->createCharacteristic(
CHARACTERISTIC_UUID2,
BLECharacteristic::PROPERTY_READ |
BLECharacteristic::PROPERTY_WRITE |
BLECharacteristic::PROPERTY_NOTIFY
);

// 두 번째 특성에 BLE2902 디스크립터 추가
pCharacteristic2->addDescriptor(new BLE2902());

// BLE 서비스 시작
pService->start();

// BLE 광고 객체 가져오기
BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();

// 광고에 서비스 UUID 추가
pAdvertising->addServiceUUID(SERVICE_UUID);

// 스캔 응답 설정 (더 많은 데이터 제공하지 않음)
pAdvertising->setScanResponse(false);

// 광고 간격 설정을 클라이언트에 위임
pAdvertising->setMinPreferred(0x0);

// BLE 광고 시작
BLEDevice::startAdvertising();

// 시리얼 모니터에 광고 시작 메시지 출력
Serial.println("BLE 장치가 광고를 시작했습니다.");
}

long adcResult1 = 0;
long adcResult2 = 0;
int printCnt = 0;
void loop() {
ads.setCompareChannels(ADS1220_MUX_0_1);
long rawResult1 = ads.getRawData();

ads.setCompareChannels(ADS1220_MUX_2_3);
long rawResult2 = ads.getRawData();

// EMA 필터 적용 (정수형)
if (!emaInitialized) {
ema1 = rawResult1;
ema2 = rawResult2;
emaInitialized = true;
} else {
ema1 = (alpha * rawResult1 + (100 - alpha) * ema1) / 100;
ema2 = (alpha * rawResult2 + (100 - alpha) * ema2) / 100;
}

// EMA 값을 KG으로 변환
float weight1 = convertADC1toKg(ema1);
float weight2 = convertADC2toKg(ema2);

// BLE를 통한 데이터 전송 (필요한 경우)
if (deviceConnected) {
unsigned long currentMillis = millis();
if (currentMillis - previousMillis >= interval) {
previousMillis = currentMillis;
// 결과 출력
// Serial.print("ADC1 Raw: ");
// Serial.print(rawResult1);
// Serial.print(" || ADC1 EMA: ");
// Serial.print(ema1);
//Serial.print(" || ADC1 Weight: ");
if(printCnt>10){
Serial.println();
printCnt = 0;
}
Serial.print(weight1, 2);
Serial.print(" ");
// Serial.print(" KG || ADC2 Raw: ");
// Serial.print(rawResult2);
// Serial.print(" || ADC2 EMA: ");
// Serial.print(ema2);
// Serial.print(" || ADC2 Weight: ");
// Serial.println(weight2, 2);
printCnt++;
// EMA 값을 문자열로 변환 (소수점 둘째자리까지)
String dataString1 = String(weight1, 2);
String dataString2 = String(weight2, 2);


복사
  // BLE를 통해 데이터 전송
  pCharacteristic->setValue(dataString1.c_str());
  pCharacteristic->notify();
  pCharacteristic2->setValue(dataString2.c_str());
  pCharacteristic2->notify();
}
}

// 연결 상태 변경 처리
if (!deviceConnected && oldDeviceConnected) {
delay(500); // 연결 해제 이벤트를 처리할 시간을 줌
pServer->startAdvertising(); // 다시 광고 시작
Serial.println("start advertising");
oldDeviceConnected = deviceConnected;
}
if (deviceConnected && !oldDeviceConnected) {
oldDeviceConnected = deviceConnected;
}

// 필요한 경우 짧은 지연 추가
}