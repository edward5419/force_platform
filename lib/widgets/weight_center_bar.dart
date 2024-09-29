import 'package:flutter/material.dart';

class WeightCenterBar extends StatelessWidget {
  final double weightPercentage;
  final double width;
  final double height;

  WeightCenterBar({
    required this.weightPercentage,
    this.width = 200,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: WeightCenterPainter(weightPercentage),
    );
  }
}

class WeightCenterPainter extends CustomPainter {
  final double weightPercentage;

  WeightCenterPainter(this.weightPercentage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // 배경 바 그리기
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height / 2),
      ),
      paint,
    );

    // 정상 영역 그리기 (중앙 40%)
    paint.color = const Color.fromARGB(255, 135, 227, 138);
    final normalRangeWidth = size.width * 0.2;
    final normalRangeStart = (size.width - normalRangeWidth) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(normalRangeStart, 0, normalRangeWidth, size.height),
        Radius.circular(size.height / 2),
      ),
      paint,
    );

    // 무게 중심 표시 그리기
    paint.color = Colors.red;
    final centerX = size.width * weightPercentage;
    canvas.drawCircle(
      Offset(centerX, size.height / 2),
      size.height / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
