import 'package:get/get.dart';

class DataRepository extends GetxService {
  final RxList<double> _dataStream1 = <double>[].obs;
  final RxList<double> _dataStream2 = <double>[].obs;

  List<double> get dataStream1 => _dataStream1.toList();
  List<double> get dataStream2 => _dataStream2.toList();

  List<double> buffer1 = [];
  double repeatData1 = 0;
  int repeatCnt1 = 0;

  void addData(double value1, double value2) {
    buffer1.insert(0, value1);

    if (value1 != 0) {
      if (repeatData1 == value1) {
        repeatCnt1 = (repeatCnt1 < 4) ? repeatCnt1 + 1 : 4; // 최대 4로 제한
      } else {
        if (repeatCnt1 != 0) {
          for (int i = 1; i <= repeatCnt1 && i < buffer1.length; i++) {
            double ratio = i / (repeatCnt1 + 1);
            double interpolatedValue = value1 + (repeatData1 - value1) * ratio;
            buffer1[i] = interpolatedValue;
          }
        }
        repeatData1 = value1;
        repeatCnt1 = 0;
      }
    }

    if (buffer1.length > 5) {
      _dataStream1.insert(0, buffer1.last);
      print("pushing ${buffer1.last}");
      buffer1.removeLast();
    } else {
      print("buffer not full yet: $buffer1");
    }

    _dataStream2.insert(0, value2);

    // 데이터 길이 제한 (예: 1000개로 제한)
    if (_dataStream1.length > 1000) {
      _dataStream1.removeLast();
      _dataStream2.removeLast();
    }
  }

  void clearData() {
    _dataStream1.clear();
    _dataStream2.clear();
    buffer1.clear();
    repeatData1 = 0;
    repeatCnt1 = 0;
  }
}
