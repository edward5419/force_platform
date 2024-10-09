import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:force_platform/controllers/data_repository.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  final DataRepository dataRepository = Get.find<DataRepository>();
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  DiscoveredDevice? espDevice;
  final String deviceName = "ESP32_BLE_Device";
  final Uuid serviceUuid = Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB");
  final Uuid characteristicUuid =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8"); // 단일 특성 UUID

  StreamSubscription<DiscoveredDevice>? scanStream;
  StreamSubscription<ConnectionStateUpdate>? connection;
  StreamSubscription<List<int>>? notificationStream;

  final RxBool _isScanning = false.obs;
  final RxBool _isConnected = false.obs;
  final RxString _receivedData1 = "".obs;
  final RxString _receivedData2 = "".obs;

  bool get isScanning => _isScanning.value;
  bool get isConnected => _isConnected.value;

  // Getter for receivedData1
  double get receivedData1 {
    final parsedValue = double.tryParse(_receivedData1.value);
    if (parsedValue != null) {
      return (parsedValue * 100).roundToDouble() / 100;
    }
    return 0.0;
  }

  // Getter for receivedData2
  double get receivedData2 {
    final parsedValue = double.tryParse(_receivedData2.value);
    if (parsedValue != null) {
      return (parsedValue * 100).roundToDouble() / 100;
    }
    return 0.0;
  }

  // Getter for totalForce
  double get totalForce {
    final double addValue = receivedData1 + receivedData2;
    final roundedValue = (addValue * 100).roundToDouble() / 100;
    return roundedValue;
  }

  // Getter for weightRatio
  double get weightRatio {
    if (receivedData2 == 0 && receivedData1 != 0) {
      return 0;
    } else if (receivedData1 == 0 && receivedData2 != 0) {
      return 1;
    } else if ((receivedData1 == 0 && receivedData2 == 0)) {
      return 0.5;
    }
    return receivedData2 / (receivedData1 + receivedData2);
  }

  @override
  void onInit() {
    super.onInit();
    checkPermissionsAndStartScan();
    print("블루투스 프로세스 시작");
  }

  @override
  void dispose() {
    scanStream?.cancel();
    connection?.cancel();
    notificationStream?.cancel();
    super.dispose();
  }

  // 권한 확인 및 스캔 시작
  void checkPermissionsAndStartScan() async {
    if (!_isConnected.value) {
      print("스캔시작");
      startScan();
    }
  }

  // BLE 디바이스 스캔 시작
  void startScan() {
    _isScanning.value = true;

    // 스캔 시작
    scanStream = flutterReactiveBle.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name == deviceName) {
        espDevice = device;
        _isScanning.value = false;

        print("디바이스 상태 : ${device.connectable}");
        scanStream?.cancel();
        connectToDevice();
      }
    }, onError: (Object error) {
      // 스캔 중 에러 처리
      _isScanning.value = false;
      print('스캔 에러: $error');
    });
  }

  // 선택한 디바이스에 연결
  void connectToDevice() {
    if (espDevice == null) return;

    // 장치에 연결
    connection = flutterReactiveBle
        .connectToDevice(
      id: espDevice!.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [characteristicUuid],
      },
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        if (!_isConnected.value) {
          _isConnected.value = true;
          print('장치에 연결되었습니다.');
          //subscribeToNotifications();
        }
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        if (_isConnected.value) {
          _isConnected.value = false;
          print('장치 연결이 해제되었습니다.');
          // 노티피케이션 구독 취소
          notificationStream?.cancel();
          notificationStream = null;
        }
        // 필요 시 재연결 로직 추가
      }
    }, onError: (Object error) {
      // 연결 중 에러 처리
      print('연결 에러: $error');
    });
  }

  // 단일 특성 노티피케이션 구독
  void subscribeToNotifications() {
    if (espDevice == null) return;

    // 기존 구독이 있으면 취소
    notificationStream?.cancel();
    notificationStream = null;

    print("subscribeToNotifications called");

    notificationStream = flutterReactiveBle
        .subscribeToCharacteristic(
      QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicUuid,
        deviceId: espDevice!.id,
      ),
    )
        .listen((data) {
      String dataString = String.fromCharCodes(data).trim();

      // 데이터 형식: "weight1,weight2"
      List<String> parts = dataString.split(',');
      if (parts.length == 2) {
        double? value1 = double.tryParse(parts[0]);
        double? value2 = double.tryParse(parts[1]);
        if (value1 != null && value2 != null) {
          _receivedData1.value = value1.toString();
          _receivedData2.value = value2.toString();

          dataRepository.addData(value1, value2);
          //print("수신된 데이터: $value1, $value2");
        } else {
          print("데이터 파싱 오류: $dataString");
        }
      } else {
        print("유효하지 않은 데이터 형식: $dataString");
      }
    }, onError: (Object error) {
      // 데이터 수신 중 에러 처리
      print('노티피케이션 에러: $error');
    });
  }

  void cancelNotification() {
    notificationStream?.cancel();
  }

  void disconnectDevice() {
    if (_isConnected.value) {
      connection?.cancel();
      notificationStream?.cancel();

      _isConnected.value = false;
      // 데이터 초기화
      dataRepository.clearData();

      print('장치 연결이 해제되었습니다.');
      // 재연결을 위해 광고 다시 시작
      //startScan();
    }
  }
}
