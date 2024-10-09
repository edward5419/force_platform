import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:force_platform/settings/chart_setting.dart';

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
      return List.generate(length, (index) {
        return avg;
      });
    }
  }
  List<double> get avgDataStream2 {
    if (_dataStream2.isEmpty)
      return [0.0];
    else {
      int length = _dataStream2.length;
      double sum = _dataStream2.reduce((a, b) => a + b);
      double avg = sum / length;
      return List.generate(length, (index) {
        return avg;
      });
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
  }
}
