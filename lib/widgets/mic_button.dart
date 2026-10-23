import 'package:flutter/material.dart';

import '../theme.dart';

/// Round glowing microphone button with a soft halo that pulses while
/// Vocax is listening.
class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.listening,
    required this.speaking,
    required this.busy,
    required this.onPressed,
  });

  final bool listening;
  final bool speaking;
  final bool busy;
  final VoidCallback onPressed;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _sync();
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final active = widget.listening || widget.speaking;
    if (active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!active && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = widget.listening
        ? Icons.stop_rounded
        : widget.speaking
            ? Icons.volume_up_rounded
            : Icons.mic_rounded;

    return Semantics(
      button: true,
      label: widget.listening ? 'Stop listening' : 'Start listening',
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final grow = _pulse.value * 14;
            return SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 132 + grow,
                    height: 132 + grow,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kBlue.withValues(alpha: 0.10 + _pulse.value * 0.08),
                    ),
                  ),
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kBlue.withValues(alpha: 0.18),
                    ),
                  ),
                  Opacity(
                    opacity: widget.busy ? 0.6 : 1,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: kBrandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: kBlue.withValues(alpha: 0.5),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: widget.busy
                          ? const Padding(
                              padding: EdgeInsets.all(26),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(icon, size: 40, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
