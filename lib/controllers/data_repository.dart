import 'package:get/get.dart';

class DataRepository extends GetxService {
  // 저장할 데이터 리스트
  final RxList<double> _dataStream1 = <double>[].obs;
  final RxList<double> _dataStream2 = <double>[].obs;

  List<double> get dataStream1 => _dataStream1.toList();
  List<double> get dataStream2 => _dataStream2.toList();

  // 데이터 추가 메서드 (보간법 적용)
  List<double> buffer1 = [];
  double repeatData1 = 0;
  double repeatCnt1 = 0;
  void addData(double value1, double value2) {
    buffer1.insert(0, value1);

    if (value1 != 0) {
      if (repeatData1 == value1) {
        repeatCnt1++;
      } else {
        if (repeatCnt1 != 0) {
          for (int i = 1; i <= repeatCnt1; i++) {
            double ratio = i / (repeatCnt1 + 1);
            double interpolatedValue = value1 + (repeatData1 - value1) * ratio;
            buffer1[i] = interpolatedValue;
          }
        }
        repeatData1 = value1;
      }
    }

    
    // 0 1 1 1
    // 1 0 0 0
    if (repeatData1 != 0) {}

    _dataStream1.insert(0, value1);
    _dataStream2.insert(0, value2);

    // 데이터 길이 제한 (예: 1000개로 제한)
    if (_dataStream1.length > 1000) {
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
