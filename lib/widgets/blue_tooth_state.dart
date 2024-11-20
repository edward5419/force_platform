// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:force_platform/controllers/bluetooth_controller.dart';
import 'package:get/get.dart';

class BlueToothState extends GetView<BluetoothController> {
  const BlueToothState({
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
          if (!controller.isConnected) {
            print("start connect");
            controller.startScan();
          } else {
            print("disconnect");
            controller.disconnectDevice();
          }
          print("Bluetooth card tapped");
        },
        borderRadius: BorderRadius.circular(15), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => Icon(
                Icons.bluetooth,
                size: 150,
                color: controller.isConnected ? Colors.blue : Color(0xFF666666),
              ),
            ),
            Obx(() => Text(
                  controller.isConnected
                      ? "Device is connected"
                      : "Device is not connected",
                  style: TextStyle(
                      color: controller.isConnected
                          ? Colors.black
                          : Color(0xFF666666),
                      fontWeight: FontWeight.bold),
                ))
          ],
        ),
      ),
    );
  }
}
