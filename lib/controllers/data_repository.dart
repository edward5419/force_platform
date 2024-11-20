import 'package:get/get.dart';
import 'package:force_platform/settings/chart_setting.dart';
import './database_helper.dart';
import 'dart:convert';
import '../models/data_record.dart';

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

  RxBool isUpdating = true.obs;

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

    _dataStream1.insert(0, value1);
    _dataRecord1.insert(0, value1);

    _dataStream2.insert(0, value2);
    _dataRecord2.insert(0, value2);

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

  // save data to database
  Future<void> saveDataRecord() async {
    final dbHelper = DatabaseHelper();
    String timestamp = DateTime.now().toIso8601String();

    await dbHelper.insertDataRecord(timestamp, _dataRecord1, _dataRecord2);

    print("Data saved at $timestamp");

    clearData();
    print('save complete');
  }

  // bring out data
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
