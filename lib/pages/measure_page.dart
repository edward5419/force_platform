import 'package:flutter/material.dart';
import 'package:force_platform/controllers/bluetooth_controller.dart';
import 'package:force_platform/controllers/data_repository.dart';
import 'package:force_platform/widgets/force_chart.dart';
import 'package:force_platform/widgets/total_weight.dart';
import 'package:force_platform/widgets/weight_center_bar.dart';
import 'package:get/get.dart';

class MeasurePage extends StatefulWidget {
  const MeasurePage({super.key});

  @override
  State<MeasurePage> createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  final BluetoothController controller = Get.find<BluetoothController>();
  final DataRepository dataRepository = Get.find<DataRepository>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.subscribeToNotifications();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.notificationStream1?.cancel();
    controller.notificationStream2?.cancel();
    dataRepository.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Measure balance")),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => TotalWeight(
                    totalWeight:
                        controller.receivedData1 + controller.receivedData2,
                  ),
                ),
              ),
              Expanded(
                  child: Card(
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Balance",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 70,
                      ),
                      Obx(
                        () => WeightCenterBar(
                          weightPercentage: controller.weightRatio,
                          height: 20,
                          width: 500,
                        ),
                      ),
                    ],
                  ),
                ),
                margin: EdgeInsets.all(10),
              ))
            ],
          ),
        ),
        Expanded(
            flex: 5,
            child: Card(
              child: Center(
                  child: Obx(
                () => ForceChart(
                  selectedDataStream1: dataRepository.dataStream1,
                  selectedDataStream2: dataRepository.dataStream2,
                ),
              )),
              margin: EdgeInsets.all(10),
            )),
      ]),
    );
  }
}
