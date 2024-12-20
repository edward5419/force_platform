import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:force_platform/settings/chart_setting.dart';

class ForceChart extends StatelessWidget {
  final List<double> selectedDataStream1;
  final List<double> selectedDataStream2;
  final int maxDisplayPoints;
  const ForceChart(
      {Key? key,
      required this.selectedDataStream1,
      required this.selectedDataStream2,
      required this.maxDisplayPoints})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // make data point

    final int len1 = selectedDataStream1.length;
    final int len2 = selectedDataStream2.length;
    final int len = len1 < len2 ? len1 : len2;
    final int displayLength = len < maxDisplayPoints ? len : maxDisplayPoints;

    final List<FlSpot> spots1 = List.generate(
      displayLength,
      (index) => FlSpot(
        index.toDouble(),
        selectedDataStream1[len1 - displayLength + index],
      ),
    );

    final List<FlSpot> spots2 = List.generate(
      displayLength,
      (index) => FlSpot(
        index.toDouble(),
        selectedDataStream2[len2 - displayLength + index],
      ),
    );

    // calculate maximum Y and X
    double minY = 0;
    double maxY = 0;
    if (spots1.isNotEmpty && spots2.isNotEmpty) {
      minY = [
        spots1.map((e) => e.y).reduce((a, b) => a < b ? a : b),
        spots2.map((e) => e.y).reduce((a, b) => a < b ? a : b)
      ].reduce((a, b) => a < b ? a : b);

      maxY = [
        spots1.map((e) => e.y).reduce((a, b) => a > b ? a : b),
        spots2.map((e) => e.y).reduce((a, b) => a > b ? a : b)
      ].reduce((a, b) => a > b ? a : b);
    }

    // add some space to Y and X
    minY = minY * 0.8;
    maxY = maxY * 1.2;

    return LineChart(
      duration: Duration.zero,
      LineChartData(

        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: const Color(0xff37434d).withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: const Color(0xff37434d).withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              reservedSize: 22,
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: const Color(0xff37434d).withOpacity(0.5),
          ),
        ),
        minX: 0,
        maxX: maxDisplayPoints.toDouble(),
        //maxX: 100,
        minY: 0,
        maxY: max(10, maxY),
        lineBarsData: [
          // first line data
          LineChartBarData(
            curveSmoothness: 0.5,
            spots: spots1,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xff23b6e6),
                Color(0xff02d39a),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: ChartSetting.showDot,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xff23b6e6).withOpacity(0.3),
                  Color(0xff02d39a).withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // second line data
          LineChartBarData(
            spots: spots2,
            isCurved: true,
            curveSmoothness: 0.5,
            gradient: const LinearGradient(
              colors: [
                Color(0xfffa0000),
                Color(0xffffdd00),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: ChartSetting.showDot,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xfffa0000).withOpacity(0.3),
                  Color(0xffffdd00).withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // X label widget
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text = Text(value.toInt().toString(), style: style);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  // Y label widget
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String label = value.toStringAsFixed(1);
    return Text(label, style: style, textAlign: TextAlign.right);
  }
}
