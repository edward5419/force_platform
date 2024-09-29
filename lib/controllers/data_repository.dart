import 'package:get/get.dart';

class DataRepository extends GetxService {
  // 저장할 데이터 리스트
  final RxList<double> _dataStream1 = <double>[].obs;
  final RxList<double> _dataStream2 = <double>[].obs;

  List<double> get dataStream1 => _dataStream1.toList();
  List<double> get dataStream2 => _dataStream2.toList();
  // 데이터 추가 메서드
  void addData(double value1, double value2) {
    _dataStream1.insert(0, value1);
    _dataStream2.insert(0, value2);

    // 데이터 길이 제한 (예: 100)
    if (_dataStream1.length > 500) {
      _dataStream1.removeLast();
      _dataStream2.removeLast();
    }
  }

  // 데이터 초기화 메서드 (필요 시)
  void clearData() {
    _dataStream1.clear();
    _dataStream2.clear();
  }
}
