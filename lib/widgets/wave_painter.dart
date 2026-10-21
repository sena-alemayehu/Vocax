import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The animated Vocax logo shown on the welcome screen.
class AnimatedWaveLogo extends StatefulWidget {
  const AnimatedWaveLogo({super.key});

  @override
  State<AnimatedWaveLogo> createState() => _AnimatedWaveLogoState();
}

class _AnimatedWaveLogoState extends State<AnimatedWaveLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 130,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: WavePainter(progress: _controller.value),
        ),
      ),
    );
  }
}

/// Paints gradient audio-wave bars that gently pulse.
class WavePainter extends CustomPainter {
  WavePainter({required this.progress});

  final double progress;

  static const int _bars = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = kBrandGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final slot = size.width / _bars;
    final barWidth = slot * 0.55;
    final centerY = size.height / 2;
    final phase = progress * 2 * math.pi;

    for (var i = 0; i < _bars; i++) {
      final t = i / (_bars - 1);
      // Bell-shaped envelope so the tallest bar sits near the middle.
      final envelope = math.exp(-math.pow((t - 0.45) * 2.6, 2).toDouble());
      final wobble = 0.82 + 0.18 * math.sin(phase + i * 0.7);
      final height =
          (size.height * 0.18 + size.height * 0.82 * envelope) * wobble;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(slot * i + slot / 2, centerY),
          width: barWidth,
          height: height,
        ),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, glow);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
