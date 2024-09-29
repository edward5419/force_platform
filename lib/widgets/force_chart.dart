import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' show max;

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
    // 최대 표시할 데이터 포인트 수
    final int maxDisplayPoints = 500;

    // 두 데이터 스트림 중 짧은 길이를 기준으로 설정
    final int len1 = selectedDataStream1.length;
    final int len2 = selectedDataStream2.length;
    final int len = len1 < len2 ? len1 : len2;
    final int displayLength = len < maxDisplayPoints ? len : maxDisplayPoints;

    // 데이터가 없는 경우 표시할 위젯
    if (len < 1) {
      return Center(child: Text('No data to display'));
    }

    // 두 데이터 스트림에서 표시할 데이터 포인트 생성
    final List<FlSpot> spots1 = List.generate(
      displayLength,
      (index) => FlSpot(
        index.toDouble(),
        selectedDataStream1[index],
      ),
    );

    final List<FlSpot> spots2 = List.generate(
      displayLength,
      (index) => FlSpot(
        index.toDouble(),
        selectedDataStream2[index],
      ),
    );

    // Y축의 최소 및 최대값 계산
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

    // Y축 범위 조정하여 간격이 0이 되지 않도록 함
    if (minY == maxY) {
      // 모든 Y값이 동일한 경우 기본 범위 설정
      minY = minY - 1;
      maxY = maxY + 1;
    } else {
      // Y축 범위에 여유 공간 추가
      minY = minY * 0.8;
      maxY = maxY * 1.2;
    }

    // Y축 간격 계산
    double horizontalInterval = (maxY - minY) / 5;

    // 간격이 0이 되지 않도록 기본값 설정
    if (horizontalInterval == 0) {
      horizontalInterval = 1.0;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
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
              interval: max(1, (displayLength / 5).floorToDouble()),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 40,
              interval: horizontalInterval,
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
        maxX: 500,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots1,
            isCurved: false,
            gradient: const LinearGradient(
              colors: [
                Color(0xff23b6e6),
                Color(0xff02d39a),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xff23b6e6).withOpacity(0.3),
                  Color(0xff02d39a).withOpacity(0.3),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: spots2,
            isCurved: false,
            gradient: const LinearGradient(
              colors: [
                Color(0xfffa0000),
                Color(0xffffdd00),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xfffa0000).withOpacity(0.3),
                  Color(0xffffdd00).withOpacity(0.3),
                ],
              ),
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
    String text;

    // 원하는 X축 라벨을 설정 (예시: 특정 값에 이름 부여)
    switch (value.toInt()) {
      case 0:
        text = 'JAN';
        break;
      case 2:
        text = 'MAR';
        break;
      case 4:
        text = 'MAY';
        break;
      case 6:
        text = 'JUL';
        break;
      case 8:
        text = 'SEP';
        break;
      case 10:
        text = 'NOV';
        break;
      default:
        text = '';
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
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
