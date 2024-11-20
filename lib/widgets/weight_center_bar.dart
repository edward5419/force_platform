import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

//currently audio function is disabled, due to error.!!!!!!!!!!
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        await _audioPlayer.setAsset('assets/sounds/beep.wav');
        await _audioPlayer.setLoopMode(LoopMode.all);
        _isInitialized = true;
      } catch (e) {
        print("Error initializing audio: $e");
      }
    }
  }

  void play() {
    if (_isInitialized) {
      _audioPlayer.play();
    }
  }

  void stop() {
    if (_isInitialized) {
      _audioPlayer.stop();
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}

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
  bool isInRedZone = false;
  double _previousWeightPercentage = 0;
  late AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
    _audioManager.initialize();
    _previousWeightPercentage = widget.weightPercentage;
  }

  @override
  void didUpdateWidget(WeightCenterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weightPercentage != oldWidget.weightPercentage) {
      _checkAndPlaySound();
    }
  }

  void _checkAndPlaySound() {
    if (!isInRedZone &&
        (widget.weightPercentage < 0.2 || widget.weightPercentage > 0.8)) {
      isInRedZone = true;
      //_audioManager.play();
    } else if (widget.weightPercentage >= 0.2 &&
        widget.weightPercentage <= 0.8) {
      if (isInRedZone) {
        //_audioManager.stop();
        isInRedZone = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
          begin: _previousWeightPercentage, end: widget.weightPercentage),
      duration: Duration(milliseconds: 300),
      onEnd: () {
        _previousWeightPercentage = widget.weightPercentage;
      },
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: WeightCenterPainter(value),
        );
      },
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height / 2),
      ),
      paint,
    );

    paint.color = Colors.red.withOpacity(0.3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.2, size.height),
        Radius.circular(size.height / 2),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.8, 0, size.width * 0.2, size.height),
        Radius.circular(size.height / 2),
      ),
      paint,
    );

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

    paint.color = Colors.red;
    final centerX = size.width * weightPercentage;
    canvas.drawCircle(
      Offset(centerX, size.height / 2),
      size.height / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(WeightCenterPainter oldDelegate) =>
      oldDelegate.weightPercentage != weightPercentage;
}
