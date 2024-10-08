import 'package:get/get.dart';
import 'package:scidart/scidart.dart'; // SciDart 전체 패키지 임포트

class DataRepository extends GetxService {
  final RxList<double> _dataStream1 = <double>[].obs;
  final RxList<double> _dataStream2 = <double>[].obs;

  List<double> get dataStream1 => _dataStream1.toList();
  List<double> get dataStream2 => _dataStream2.toList();

  List<double> buffer1 = [];
  List<double> buffer2 = []; // dataStream2에 대한 버퍼 추가
  int windowSize = 5; // 이동 평균 필터의 윈도우 크기

  // 이동 평균 필터 함수
  double movingAverage(List<double> data) {
    if (data.length < windowSize) {
      return data.first; // 데이터가 충분하지 않으면 첫 번째 값 반환
    }

    double sum = 0;
    for (int i = 0; i < windowSize; i++) {
      sum += data[i];
    }
    return sum / windowSize;
  }

  void addData(double value1, double value2) {
    // 입력 데이터를 buffer1에 추가
    buffer1.insert(0, value1);

    // buffer1에 대한 이동 평균 필터 적용
    if (buffer1.length >= windowSize) {
      double filteredValue1 = movingAverage(buffer1);

      // 필터링된 값을 dataStream1에 추가
      _dataStream1.insert(0, filteredValue1);
      print(
          "Filtered data pushed to dataStream1 (Moving Avg): $filteredValue1");

      // buffer1에서 마지막 값 제거
      buffer1.removeLast();
    } else {
      print("Buffer1 not full yet: $buffer1");
    }

    // 입력 데이터를 buffer2에 추가
    buffer2.insert(0, value2);

    // buffer2에 대한 이동 평균 필터 적용
    if (buffer2.length >= windowSize) {
      double filteredValue2 = movingAverage(buffer2);

      // 필터링된 값을 dataStream2에 추가
      _dataStream2.insert(0, filteredValue2);
      print(
          "Filtered data pushed to dataStream2 (Moving Avg): $filteredValue2");

      // buffer2에서 마지막 값 제거
      buffer2.removeLast();
    } else {
      print("Buffer2 not full yet: $buffer2");
    }

    // 데이터 길이 제한 (예: 1000개로 제한)
    if (_dataStream1.length > 1000) {
      _dataStream1.removeLast();
    }
    if (_dataStream2.length > 1000) {
      _dataStream2.removeLast();
    }
  }

  void clearData() {
    _dataStream1.clear();
    _dataStream2.clear();
    buffer1.clear();
    buffer2.clear(); // buffer2도 초기화
  }
}
