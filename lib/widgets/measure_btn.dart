// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:force_platform/controllers/bluetooth_controller.dart';
import 'package:get/get.dart';

class MeasureBtn extends GetView<BluetoothController> {
  const MeasureBtn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.all(20),
      child: InkWell(
        // InkWell을 Card 내부로 이동
        onTap: () {
          // 터치 시 실행할 동작
          if (controller.isConnected) {
            Get.toNamed("/measure_page");
            print("Fitness card tapped");
          } else {
            //nothing
          }
        },
        borderRadius: BorderRadius.circular(15), // Card와 같은 모서리 반경
        child: Obx(
          () => Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                Icons.fitness_center,
                size: 150,
                color: controller.isConnected ? Colors.blue : Color(0xFF666666),
              ),
              controller.isConnected
                  ? Text(
                      "Measure",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    )
                  : Text(
                      "you need to connect device first",
                      style: TextStyle(
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.bold),
                    )
            ]),
          ),
        ),
      ),
    );
  }
}
