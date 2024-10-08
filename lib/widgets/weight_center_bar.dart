import 'package:flutter/material.dart';
//import 'package:audioplayers/audioplayers.dart'; // 소리 재생을 위한 라이브러리 추가

class WeightCenterBar extends StatefulWidget {
  final double weightPercentage;
  final double width;
  final double height;

  WeightCenterBar({
    required this.weightPercentage,
    this.width = 200,
    this.height = 20,
  });

  @override
  _WeightCenterBarState createState() => _WeightCenterBarState();
}

class _WeightCenterBarState extends State<WeightCenterBar> {
  // final AudioPlayer _audioPlayer = AudioPlayer(); // AudioPlayer 인스턴스 생성

  @override
  void initState() {
    super.initState();

    // 앱이 멈추지 않도록 비동기적으로 소리를 재생
    //_checkAndPlaySound();
  }

  @override
  void didUpdateWidget(WeightCenterBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // weightPercentage가 변경될 때만 소리를 재생
    if (widget.weightPercentage != oldWidget.weightPercentage) {
      //_checkAndPlaySound();
    }
  }

  // 비동기적으로 경고음을 재생하는 함수
  // Future<void> _checkAndPlaySound() async {
  //   if (widget.weightPercentage < 0.1 || widget.weightPercentage > 0.9) {
  //     // 경고음 재생 (로컬 혹은 원격 경로의 사운드를 재생할 수 있음)
  //     await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
  //   }
  // }

  @override
  void dispose() {
    //_audioPlayer.dispose(); // AudioPlayer 자원 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: WeightCenterPainter(widget.weightPercentage),
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
