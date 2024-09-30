import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:force_platform/controllers/data_repository.dart';
import 'package:get/get.dart';

class BluetoothController extends GetxController {
  final DataRepository dataRepository = Get.find<DataRepository>();
  final flutterReactiveBle = FlutterReactiveBle();
  DiscoveredDevice? espDevice;
  final String deviceName = "ESP32_BLE_Device";
  final Uuid serviceUuid = Uuid.parse("0000180A-0000-1000-8000-00805F9B34FB");
  final Uuid characteristicUuid1 =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  final Uuid characteristicUuid2 =
      Uuid.parse("beb5483e-36e1-4688-b7f5-ea07361b26a9"); // 두 번째 특성 UUID

  StreamSubscription<DiscoveredDevice>? scanStream;
  StreamSubscription<ConnectionStateUpdate>? connection;
  StreamSubscription<List<int>>? notificationStream1;
  StreamSubscription<List<int>>? notificationStream2;

  final RxBool _isScanning = false.obs;
  final RxBool _isConnected = false.obs;
  final RxString _receivedData1 = "".obs;
  final RxString _receivedData2 = "".obs;

  bool get isScanning => _isScanning.value;
  bool get isConnected => _isConnected.value;

  double get receivedData1 {
    final parsedValue = double.tryParse(_receivedData1.value);
    if (parsedValue != null) {
      return (parsedValue * 100).roundToDouble() / 100;
    }
    return 0.0;
  }

  double get receivedData2 {
    final parsedValue = double.tryParse(_receivedData2.value);
    if (parsedValue != null) {
      return (parsedValue * 100).roundToDouble() / 100;
    }
    return 0.0;
  }

  double get totalForce {
    final double addValue = receivedData1 + receivedData2;
    final roundedValue = (addValue * 100).roundToDouble() / 100;
    return roundedValue;
  }

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
  }

  @override
  void dispose() {
    scanStream?.cancel();
    connection?.cancel();
    notificationStream1?.cancel();
    notificationStream2?.cancel();
    super.dispose();
  }

  // 권한 확인 (필요 시 구현)
  void checkPermissionsAndStartScan() async {
    // Android의 경우 위치 권한 및 BLE 권한을 요청해야 합니다.
    // 'permission_handler' 패키지를 사용할 수 있습니다.
    // 여기서는 생략하고 바로 스캔을 시작합니다.
    startScan();
  }

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

        scanStream?.cancel();
        connectToDevice();
      }
    }, onError: (Object error) {
      // 스캔 중 에러 처리

      _isScanning.value = false;

      print('스캔 에러: $error');
    });
  }

  void connectToDevice() {
    if (espDevice == null) return;

    // 장치에 연결
    connection = flutterReactiveBle
        .connectToDevice(
      id: espDevice!.id,
      servicesWithCharacteristicsToDiscover: {
        serviceUuid: [characteristicUuid1, characteristicUuid2],
      },
      connectionTimeout: const Duration(seconds: 5),
    )
        .listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        _isConnected.value = true;

        print('장치에 연결되었습니다.');
        // subscribeToNotifications();
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        _isConnected.value = false;

        print('장치 연결이 해제되었습니다.');
      }
    }, onError: (Object error) {
      // 연결 중 에러 처리
      print('연결 에러: $error');
    });
  }

  void subscribeToNotifications() {
    if (espDevice == null) return;

    // 첫 번째 특성 노티피케이션 구독
    notificationStream1 = flutterReactiveBle
        .subscribeToCharacteristic(
      QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicUuid1,
        deviceId: espDevice!.id,
      ),
    )
        .listen((data) {
      _receivedData1.value = String.fromCharCodes(data);

      //print('수신된 데이터 1: $');
    }, onError: (Object error) {
      // 데이터 수신 중 에러 처리
      print('노티피케이션 1 에러: $error');
    });

    // 두 번째 특성 노티피케이션 구독
    notificationStream2 = flutterReactiveBle
        .subscribeToCharacteristic(
      QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicUuid2,
        deviceId: espDevice!.id,
      ),
    )
        .listen((data) {
      _receivedData2.value = String.fromCharCodes(data);

      //print('수신된 데이터 2: $receivedData2');
      //데이터 저장
      dataRepository.addData(receivedData1, receivedData2);
    }, onError: (Object error) {
      // 데이터 수신 중 에러 처리
      print('노티피케이션 2 에러: $error');
    });
  }

  void disconnectDevice() {
    if (_isConnected.value) {
      connection?.cancel();
      notificationStream1?.cancel();
      notificationStream2?.cancel();

      _isConnected.value = false;
      _receivedData1.value = "";
      _receivedData2.value = "";

      print('장치 연결이 해제되었습니다.');
      // 재연결을 위해 광고 다시 시작
      startScan();
    }
  }
}
