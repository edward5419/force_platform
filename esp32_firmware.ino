#include <ADS1220_WE.h>
#include <SPI.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define ADS1220_CS_PIN    5  // chip select pin
#define ADS1220_DRDY_PIN  26 // data ready pin 
#define rgbpin 16
const int LED_PIN = 16; // LED pin number
bool ledState = true;

// Pointer to the BLE server object
BLEServer* pServer = NULL;

// Pointer to the BLE characteristic object (single characteristic used)
BLECharacteristic* pCharacteristic = NULL;

// Variable indicating device connection status
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Data transmission interval management variable
unsigned long previousMillis = 0;
const long interval = 20;  // Increase data transmission interval to 20ms

// Service and characteristic UUID definitions
#define SERVICE_UUID        "0000180A-0000-1000-8000-00805F9B34FB"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Kalman filter variables
float kalman_gain1 = 0.05;
float kalman_gain2 = 0.05;
float estimate1 = 0;
float estimate2 = 0;
float error_estimate1 = 0.2;  // Initial estimation error decrease
float error_estimate2 = 0.2;  // Initial estimation error decrease
float error_measure = 2.0;    // Measurement error increase

// Variables for average calculation
const int numReadings = 200;  // Number of samples for average calculation
long readings1[numReadings];
long readings2[numReadings];
int readIndex = 0;
long total1 = 0;
long total2 = 0;
int zeroPoint1 = 0;
int zeroPoint2 = 0;

ADS1220_WE ads = ADS1220_WE(ADS1220_CS_PIN, ADS1220_DRDY_PIN);

// BLE server callback class definition
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
      deviceConnected = true;
      digitalWrite(LED_PIN, HIGH); // Turn on LED when connected
    };

    void onDisconnect(BLEServer* pServer) override {
      deviceConnected = false;
      digitalWrite(LED_PIN, LOW); // Turn off LED when disconnected
    }
};


//this ADC-KG model is not complete. you need to make your own model according to your load cells.
// Function to convert ADC value to Kg
float convertADC1toKg(long value) {
  float kg = 1.0/3900.0*value - (zeroPoint1)/3900.0;
  if(kg < 0.02){
    kg = 0;
  }
  return kg;
}

float convertADC2toKg(long value) {
  float kg = 1.0/5223.0*value - (zeroPoint2)/5223.0;
  if(kg < 0.02){
    kg = 0;
  }
  return kg;
}

void setup(){
  pinMode(15, OUTPUT);
  pinMode(ADS1220_DRDY_PIN, INPUT); // Set DRDY pin to input mode
  pinMode(LED_PIN, OUTPUT);          // Set LED pin to output mode
  Serial.begin(115200);
  
  // Initialize ADS1220
  if(!ads.init()){
    Serial.println("ADS1220 is not connected!");
    while(1);
  }

  ads.setDataRate(ADS1220_DR_LVL_6);
  ads.setConversionMode(ADS1220_CONTINUOUS);
  ads.setOperatingMode(ADS1220_TURBO_MODE);
  ads.setFIRFilter(ADS1220_50HZ_60HZ);
  ads.bypassPGA(true);
  ads.setSPIClockSpeed(1000000); // Set SPI clock speed to 1MHz for stability
  ads.setGain(ADS1220_GAIN_32);
  ads.start();

  // Initialize BLE
  BLEDevice::init("ESP32_BLE_Device");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  Serial.println("BLE device is advertising.");
  neopixelWrite(rgbpin,0,0,255);
  
  // Initialize average calculation arrays
  for (int i = 0; i < numReadings; i++) {
    readings1[i] = 0;
    readings2[i] = 0;
  }

  ads.setCompareChannels(ADS1220_MUX_0_1);
  zeroPoint1 = ads.getRawData();
  
  // Set ADS1220 MUX and read the second data
  ads.setCompareChannels(ADS1220_MUX_2_3);
  zeroPoint2 = ads.getRawData();
}

// Kalman filter function
float kalmanFilter(float measurement, float &estimate, float &error_estimate, float &kalman_gain) {
  float error_estimate_temp = error_estimate + 0.001;  // Increase process noise
  kalman_gain = error_estimate_temp / (error_estimate_temp + error_measure);
  estimate = estimate + kalman_gain * (measurement - estimate);
  error_estimate = (1 - kalman_gain) * error_estimate_temp;
  return estimate;
}

int printCnt = 0;
int zeroCnt = 0;
void loop() {
  // Data transmission via BLE (single characteristic used)
  if (deviceConnected) {
    // Set ADS1220 MUX and read the first data
    ads.setCompareChannels(ADS1220_MUX_0_1);
    long rawResult1 = ads.getRawData();

    // Set ADS1220 MUX and read the second data
    ads.setCompareChannels(ADS1220_MUX_2_3);
    long rawResult2 = ads.getRawData();
    Serial.print("Raw Result 2: ");
    Serial.println(rawResult2);

    // Average calculation
    total1 = total1 - readings1[readIndex];
    total2 = total2 - readings2[readIndex];
    readings1[readIndex] = rawResult1;
    readings2[readIndex] = rawResult2;
    total1 = total1 + readings1[readIndex];
    total2 = total2 + readings2[readIndex];
    readIndex = (readIndex + 1) % numReadings;

    long average1 = total1 / numReadings;
    long average2 = total2 / numReadings;

    // Apply Kalman filter
    float filtered1 = kalmanFilter(average1, estimate1, error_estimate1, kalman_gain1);
    float filtered2 = kalmanFilter(average2, estimate2, error_estimate2, kalman_gain2);
    
    if(zeroCnt < 1000){
      neopixelWrite(rgbpin,255,0,0);
      zeroPoint1 = filtered1;
      zeroPoint2 = filtered2;
      Serial.println("Calibrating...");
      Serial.println(zeroPoint1);
      Serial.println(zeroPoint2);
      zeroCnt++;
    } else {
      neopixelWrite(rgbpin,0,255,0);
    }
    
    Serial.print("    fil2: ");
    Serial.println(filtered2);
    
    // Convert filtered values to KG
    float weight1 = convertADC1toKg(filtered1);
    float weight2 = convertADC2toKg(filtered2);

    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;
      
      // Toggle LED state
      ledState = !ledState;
      digitalWrite(LED_PIN, ledState);
      
      if(printCnt > 30) {
        printCnt = 0;
      }
      printCnt++;
      
      // Combine two data into a single string
      String dataString = String(weight1, 2) + "," + String(weight2, 2);
      
      pCharacteristic->setValue(dataString.c_str());
      pCharacteristic->notify();
    }
  }

  // Handle connection state changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Wait briefly after disconnection
    pServer->startAdvertising();
    Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
