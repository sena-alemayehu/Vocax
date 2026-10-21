import 'package:flutter/material.dart';

/// The Vocax logo, gently "breathing", shown on the welcome screen.
class AnimatedWaveLogo extends StatefulWidget {
  const AnimatedWaveLogo({super.key, this.width = 210});

  final double width;

  @override
  State<AnimatedWaveLogo> createState() => _AnimatedWaveLogoState();
}

class _AnimatedWaveLogoState extends State<AnimatedWaveLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Image.asset(
        'assets/images/logo.png',
        width: widget.width,
        fit: BoxFit.contain,
        semanticLabel: 'Vocax logo',
      ),
    );
  }
}
