// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:force_platform/controllers/bluetooth_controller.dart';
import 'package:force_platform/widgets/blue_tooth_state.dart';
import 'package:force_platform/widgets/measure_btn.dart';
import 'package:get/get.dart';

class HomePage extends GetView<BluetoothController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HomePage")),
      body: HomePageBody(),
    );
  }
}

class HomePageBody extends StatelessWidget {
  const HomePageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: BlueToothState(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: MeasureBtn(),
              ),
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.all(20),
                  child: InkWell(
                    onTap: () {
                      Get.toNamed('/saved_records_page');
                      print("Pending actions card tapped");
                    },
                    borderRadius: BorderRadius.circular(15), 
                    child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pending_actions,
                              size: 150,
                              color: Colors.blue,
                            ),
                            Text(
                              "Record",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          ]),
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
