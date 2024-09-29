// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, sort_child_properties_last

#include <ADS1220_WE.h>
#include <SPI.h>
#include <BLEDevice.h>    // BLEDevice 클래스 및 BLE 초기화 관련 함수 제공
#include <BLEServer.h>    // BLEServer 클래스 및 서버 관련 함수 제공
#include <BLEUtils.h>     // BLE 관련 유틸리티 함수 제공
#include <BLE2902.h>      // BLE2902 디스크립터 클래스 제공

#define ADS1220_CS_PIN    5 // chip select pin
#define ADS1220_DRDY_PIN  26 // data ready pin 

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
const long interval = 200;  // 예시로 200ms로 설정 

// 서비스 및 특성 UUID 정의 (표준 Device Information Service UUID 사용)
#define SERVICE_UUID        "0000180A-0000-1000-8000-00805F9B34FB" // Device Information Service UUID (0x180A)
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8" // 첫 번째 커스텀 Characteristic UUID
#define CHARACTERISTIC_UUID2 "beb5483e-36e1-4688-b7f5-ea07361b26a9" // 두 번째 커스텀 Characteristic UUID

// BLE 서버 콜백 클래스 정의 (BLEServerCallbacks 클래스 상속)
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) override {
      deviceConnected = false;
    }
};

// 필터 변수 선언
float ema1 = 0.0; // 첫 번째 채널의 EMA 값
float ema2 = 0.0; // 두 번째 채널의 EMA 값
const float alpha = 0.1; // 평활화 계수 (0 < alpha < 1)
bool emaInitialized = false; // EMA 초기화 여부

ADS1220_WE ads = ADS1220_WE(ADS1220_CS_PIN, ADS1220_DRDY_PIN);

void setup(){
  Serial.begin(9600);
  if(!ads.init()){
    Serial.println("ADS1220 is not connected!");
    while(1);
  }

  ads.bypassPGA(true); 

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
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // BLE 특성에 BLE2902 디스크립터 추가
  pCharacteristic->addDescriptor(new BLE2902());

  // 두 번째 BLE 특성 생성 및 속성 설정
  pCharacteristic2 = pService->createCharacteristic(
                      CHARACTERISTIC_UUID2,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
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

void loop(){
  
  long adcResult1 = 0;
  long adcResult2 = 0;

  ads.setCompareChannels(ADS1220_MUX_0_1);
  adcResult1 = ads.getRawData();

  Serial.print("AIN0 vs. AIN1 (raw): ");  // raw data
  Serial.println(adcResult1);
  
  ads.setCompareChannels(ADS1220_MUX_2_3);
  adcResult2 = ads.getRawData();
  Serial.print("AIN2 vs. AIN3 (raw): ");  // raw data
  Serial.println(adcResult2);

  // EMA 필터 적용
  if(!emaInitialized){
    ema1 = adcResult1;
    ema2 = adcResult2;
    emaInitialized = true;
  }
  else{
    ema1 = alpha * adcResult1 + (1 - alpha) * ema1;
    ema2 = alpha * adcResult2 + (1 - alpha) * ema2;
  }

  // 필터링된 값 출력 (디버깅용)
  Serial.print("AIN0 vs. AIN1 (EMA): ");
  Serial.println(ema1);
  Serial.print("AIN2 vs. AIN3 (EMA): ");
  Serial.println(ema2);

  // 필터링된 값을 BLE 특성에 업데이트
  if (deviceConnected) {
    // 첫 번째 특성 업데이트
    pCharacteristic->setValue((char*)&ema1, sizeof(ema1));
    pCharacteristic->notify();

    // 두 번째 특성 업데이트
    pCharacteristic2->setValue((char*)&ema2, sizeof(ema2));
    pCharacteristic2->notify();
  }

  delay(interval); // 데이터 전송 간격 설정
}