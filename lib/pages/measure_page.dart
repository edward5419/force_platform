import 'package:flutter/material.dart';
import 'package:force_platform/controllers/bluetooth_controller.dart';
import 'package:force_platform/controllers/data_repository.dart';
import 'package:force_platform/widgets/force_chart.dart';
import 'package:force_platform/widgets/total_weight.dart';
import 'package:force_platform/widgets/weight_center_bar.dart';
import 'package:get/get.dart';
import 'package:force_platform/settings/chart_setting.dart';

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
    super.initState();
    controller.subscribeToNotifications();
  }

  @override
  void dispose() {
    controller.cancelNotification();
    dataRepository.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Measure balance"),
        actions: [
          ElevatedButton(
              onPressed: () async {
                try {
                  await dataRepository.saveDataRecord();
                  Get.back();
                  Get.snackbar('Success', 'Data saved');
                  print("백!");
                } catch (e) {
                  print('Error saving data: $e');
                  Get.snackbar('Error', 'Failed to save data');
                }
              },
              child: Text("Save and exit")),
        ],
      ),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => TotalWeight(
                    totalWeight: controller.totalForce,
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
          flex: 6,
          child: Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Center(
                    child: Obx(
                      () {
                        if (dataRepository.showAvgValue.value) {
                          return ForceChart(
                            selectedDataStream1: dataRepository.avgDataStream1,
                            selectedDataStream2: dataRepository.avgDataStream2,
                            maxDisplayPoints: ChartSetting.maxX,
                          );
                        } else {
                          return ForceChart(
                              selectedDataStream1: dataRepository.dataStream1,
                              selectedDataStream2: dataRepository.dataStream2,
                              maxDisplayPoints: ChartSetting.maxX);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        // ElevatedButton(
                        //   onPressed: () {
                        //     dataRepository.toggleUpdating();
                        //   },
                        //   child: Obx(() => Text(
                        //         dataRepository.isUpdating.value
                        //             ? "Stop Updating"
                        //             : "Start Updating",
                        //         style: TextStyle(fontSize: 12),
                        //       )),
                        //   style: ElevatedButton.styleFrom(
                        //     padding:
                        //         EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //     minimumSize: Size(0, 0),
                        //   ),
                        // ),

                        ElevatedButton(
                          onPressed: () {
                            dataRepository.toggleShowAvgValue();
                          },
                          child: Obx(() => Text(
                                "Average",
                                style: dataRepository.showAvgValue.value
                                    ? TextStyle(fontSize: 18)
                                    : TextStyle(
                                        fontSize: 18, color: Colors.grey),
                              )),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size(0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
