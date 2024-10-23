import 'package:get/get.dart';
import 'package:force_platform/settings/chart_setting.dart';
import './database_helper.dart'; // 실제 경로로 변경하세요
import 'dart:convert';

class DataRepository extends GetxService {
  final RxList<double> _dataStream1 = <double>[].obs;
  final RxList<double> _dataStream2 = <double>[].obs;

  final showAvgValue = false.obs;

  final List<double> _dataRecord1 = <double>[];
  final List<double> _dataRecord2 = <double>[];

  List<double> get dataStream1 => _dataStream1.toList();
  List<double> get dataStream2 => _dataStream2.toList();

  List<double> get avgDataStream1 {
    if (_dataStream1.isEmpty)
      return [0.0];
    else {
      int length = _dataStream1.length;
      double sum = _dataStream1.reduce((a, b) => a + b);
      double avg = sum / length;
      return List.generate(length, (index) => avg);
    }
  }

  List<double> get avgDataStream2 {
    if (_dataStream2.isEmpty)
      return [0.0];
    else {
      int length = _dataStream2.length;
      double sum = _dataStream2.reduce((a, b) => a + b);
      double avg = sum / length;
      return List.generate(length, (index) => avg);
    }
  }

  // 데이터 업데이트를 제어하는 플래그
  RxBool isUpdating = true.obs;

  // 업데이트 플래그를 토글하는 메서드
  void toggleUpdating() {
    isUpdating.value = !isUpdating.value;
    print("Updating is now ${isUpdating.value ? 'enabled' : 'disabled'}");
  }

  void toggleShowAvgValue() {
    showAvgValue.value = !showAvgValue.value;
  }

  void addData(double value1, double value2) {
    if (!isUpdating.value) {
      print("Updates are stopped. Data not added.");
      return;
    }

    // 스트림1에 데이터 추가
    _dataStream1.insert(0, value1);
    _dataRecord1.insert(0, value1);

    // 스트림2에 데이터 추가
    _dataStream2.insert(0, value2);
    _dataRecord2.insert(0, value2);
    // 데이터 길이 제한 (예: 1000개로 제한)
    if (_dataStream1.length > ChartSetting.maxX) {
      _dataStream1.removeLast();
    }
    if (_dataStream2.length > ChartSetting.maxX) {
      _dataStream2.removeLast();
    }
  }

  void clearData() {
    _dataStream1.clear();
    _dataStream2.clear();
    _dataRecord1.clear();
    _dataRecord2.clear();
  }

  // 데이터 기록을 데이터베이스에 저장하는 메서드
  Future<void> saveDataRecord() async {
    final dbHelper = DatabaseHelper();
    String timestamp = DateTime.now().toIso8601String();

    await dbHelper.insertDataRecord(timestamp, _dataRecord1, _dataRecord2);

    print("Data saved at $timestamp");

    //필요에 따라 저장 후 기록을 초기화할 수 있습니다.
    clearData();
    print('세이브 완료');
  }

  // 저장된 데이터 기록을 모두 가져오는 메서드
  Future<List<DataRecord>> fetchDataRecords() async {
    final dbHelper = DatabaseHelper();
    final records = await dbHelper.getAllDataRecords();

    return records.map((record) {
      return DataRecord(
        id: record['id'],
        timestamp: record['timestamp'],
        dataStream1: List<double>.from(jsonDecode(record['dataStream1'])),
        dataStream2: List<double>.from(jsonDecode(record['dataStream2'])),
      );
    }).toList();
  }
}

// DataRecord 모델 클래스
class DataRecord {
  final int id;
  final String timestamp;
  final List<double> dataStream1;
  final List<double> dataStream2;

  DataRecord({
    required this.id,
    required this.timestamp,
    required this.dataStream1,
    required this.dataStream2,
  });
}
