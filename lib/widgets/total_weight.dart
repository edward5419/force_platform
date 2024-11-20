// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, sort_child_properties_last

import 'package:flutter/material.dart';

class TotalWeight extends StatelessWidget {
  final double totalWeight;
  const TotalWeight({super.key, required this.totalWeight});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Total Force",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "$totalWeight",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 110,
                    color: Colors.blue,
                  ),
                ),

                SizedBox(width: 4), 
                Text(
                  "KG",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // 
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
