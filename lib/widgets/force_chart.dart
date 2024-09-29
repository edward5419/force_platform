import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ForceChart extends StatelessWidget {
  final List<double> selectedDataStream1;
  final List<double> selectedDataStream2;

  const ForceChart({
    Key? key,
    required this.selectedDataStream1,
    required this.selectedDataStream2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 데이터 포인트 생성
    final int maxDisplayPoints = 100; // 최대 표시할 데이터 포인트 수
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

    // 최대 최소 Y값 계산
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

    // 여유 공간 추가
    minY = minY * 0.8;
    maxY = maxY * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          verticalInterval: displayLength / 5,
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
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: bottomTitleWidgets,
              interval: displayLength / 5,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 40,
              interval: (maxY - minY) / 5,
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
        maxX: displayLength.toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
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
              show: false,
            ),
            belowBarData: BarAreaData(
              show: false,
            ),
          ),
          LineChartBarData(
            spots: spots2,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xfffa0000),
                Color(0xffffdd00),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: false,
            ),
          ),
        ],
      ),
    );
  }

  // X축 라벨 위젯
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

  // Y축 라벨 위젯
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
