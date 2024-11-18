import 'package:flutter/material.dart';
import 'package:force_platform/controllers/bluetooth_controller.dart';
import 'package:force_platform/controllers/data_repository.dart';
import 'package:force_platform/widgets/force_chart.dart';
import 'package:force_platform/widgets/total_weight.dart';
import 'package:force_platform/widgets/weight_center_bar.dart';
import 'package:get/get.dart';
import 'package:force_platform/settings/chart_setting.dart';

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DataRecord record = Get.arguments["record"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Measure balance",
          style: TextStyle(),
        ),
      ),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            Expanded(
                child: Card(
              child: Column(
                children: [
                  Text(
                    "Compare Average",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      Text(
                        "L : ${getAvg(record.dataStream1)}",
                        style: TextStyle(fontSize: 40),
                      ),
                      Text(
                        "R : ${getAvg(record.dataStream2)}",
                        style: TextStyle(fontSize: 40),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  )
                ],
              ),
              elevation: 5,
            )),
            Expanded(
                child: Card(
              child: Column(
                children: [
                  Text(
                    "Compare Peak",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      Text(
                        "L : ${findMaxValue(record.dataStream1)}",
                        style: TextStyle(fontSize: 40),
                      ),
                      Text(
                        "R : ${findMaxValue(record.dataStream2)}",
                        style: TextStyle(fontSize: 40),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  )
                ],
              ),
              elevation: 5,
            )),
            Expanded(
                child: Card(
              child: Column(
                children: [
                  Text(
                    "Abs Deviation work amount(Kg*s)",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      Text(
                        "${workAmount(record.dataStream1, record.dataStream2)}",
                        style: TextStyle(fontSize: 40),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  )
                ],
              ),
              elevation: 5,
            )),
          ]),
        ),
        Expanded(
          flex: 6,
          child: Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: ForceChart(
                selectedDataStream1: record.dataStream1,
                selectedDataStream2: record.dataStream2,
                maxDisplayPoints: record.dataStream1.length,
              )),
            ),
          ),
        ),
      ]),
    );
  }
}

double getAvg(List<double> list) {
  // 0이 아닌 값만 필터링
  List<double> filteredList = list.where((value) => value != 0).toList();

  // 필터링된 리스트가 비어있지 않은지 확인
  if (filteredList.isEmpty) {
    return 0; // 0으로 반환하거나 다른 기본값을 설정
  }

  double sum = filteredList.reduce((a, b) => a + b);
  double result = ((sum / filteredList.length) * 100).roundToDouble() / 100;
  return result;
}

double findMaxValue(List<double> numbers) {
  if (numbers.isEmpty) throw Exception("List is empty");

  return numbers.reduce((a, b) => a > b ? a : b);
}

double workAmount(List<double> list1, List<double> list2) {
  double avg1 = getAvg(list1);
  double avg2 = getAvg(list2);

  List<double> gapList1 = list1.map((data) {
    if (data == 0.0) {
      return 0.0;
    } else {
      double outcome = data - avg1;
      if (outcome < 0) {
        outcome = outcome * (-1);
      }

      return outcome;
    }
  }).toList();

  List<double> gapList2 = list2.map((data) {
    if (data == 0.0) {
      return 0.0;
    } else {
      double outcome = data - avg2;
      if (outcome < 0) {
        outcome = outcome * (-1);
      }

      return outcome;
    }
  }).toList();

  double sum1 = gapList1.reduce((a, b) => a + b);
  double sum2 = gapList2.reduce((a, b) => a + b);
  double result = sum1 + sum2;
  result = result / 50;
  result = result * (avg1 + avg2) / 20;
  result = (result * 100).roundToDouble() / 100;

  return result;
}
