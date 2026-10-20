import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
const Color kBackground = Color(0xFF050A14);
const Color kSurface = Color(0xFF0F1626);
const Color kBlue = Color(0xFF3D8BFF);
const Color kViolet = Color(0xFF7B5CFF);

const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [kBlue, kViolet],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VocaxApp());
}

class VocaxApp extends StatelessWidget {
  const VocaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome screen
// ---------------------------------------------------------------------------
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
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

  void _getStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.0,
            colors: [Color(0xFF0B1630), kBackground],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: 170,
                  height: 130,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: WavePainter(
                          progress: _controller.value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Vocax',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Your voice. Your world.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'A multilingual AI voice assistant\nfor everyday life.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(flex: 4),
                GradientButton(
                  label: 'Get Started',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _getStarted,
                ),
                const SizedBox(height: 24),
                const CopyrightFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------// Copyright footer
// ---------------------------------------------------------------------------
class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} Sena Alemayehu. All rights reserved.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable gradient button
// ---------------------------------------------------------------------------
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: kBrandGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: kBlue.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onPressed,
            child: SizedBox(
              height: 64,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, color: Colors.white),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        textAlign: leadingIcon != null
                            ? TextAlign.left
                            : TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (icon != null)
                      Icon(icon, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated audio-wave logo
// ---------------------------------------------------------------------------
class WavePainter extends CustomPainter {
  WavePainter({required this.progress});

  final double progress;

  static const int _bars = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = kBrandGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..shader = kBrandGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        14,
      )
      ..color = Colors.white.withValues(alpha: 0.4);

    final slot = size.width / _bars;
    final barWidth = slot * 0.55;
    final centerY = size.height / 2;
    final phase = progress * 2 * math.pi;

    for (var i = 0; i < _bars; i++) {
      final t = i / (_bars - 1);
      final envelope = math.exp(
        -math.pow((t - 0.45) * 2.6, 2).toDouble(),
      );
      final wobble = 0.82 + 0.18 * math.sin(phase + i * 0.7);
      final height =
          (size.height * 0.18 + size.height * 0.82 * envelope) *
              wobble;

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
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
// Home screen: voice assistant
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _listening = false;
  bool _busy = false;
  bool _speaking = false;
  bool _responding = false;

  String _recognizedText = '';
  String _status = 'Tap the button and say "Hello Vocax".';

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    _tts.setStartHandler(() {
      if (mounted) {
        setState(() => _speaking = true);
      }
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _speaking = false);
      }
    });

    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() => _speaking = false);
      }
    });

    _tts.setErrorHandler((message) {
      if (!mounted) return;

      setState(() {
        _speaking = false;
        _status = 'Speech output error: $message';
      });
    });

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Voice setup failed: $error');
    }
  }

  Future<void> _startListening() async {
    if (_busy || _listening || _responding) return;

    setState(() {
      _busy = true;
      _status = 'Checking speech recognition...';
      _recognizedText = '';
    });

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          setState(() {
            _listening = _speech.isListening;
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _listening = false;
            _status = 'Speech error: ${error.errorMsg}';
          });
        },
      );

      if (!available) {
        if (!mounted) return;

        setState(() {
          _listening = false;
          _status =
              'Speech recognition is unavailable. Check your microphone permission and Android speech service.';
        });
        return;
      }

      await _tts.stop();

      if (!mounted) return;

      setState(() {
        _status = 'Listening... Say "Hello Vocax".';
        _listening = true;
      });

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult &&
              result.recognizedWords.trim().isNotEmpty) {
            _respond(result.recognizedWords.trim());
          }
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _listening = false;
        _status = 'Could not start listening: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _respond(String words) async {
    if (_responding) return;

    _responding = true;

    try {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _listening = false;
        _status = 'Vocax is preparing a response...';
      });

      final normalized = words
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final String reply;

      if (normalized.contains('hello vocax') ||
          normalized.contains('hey vocax') ||
          normalized == 'hi vocax') {
        reply = 'Hello! I am Vocax. How can I help you?';
      } else if (normalized.contains('how are you')) {
        reply = 'I am ready to help you. What would you like to do?';
      } else if (normalized.contains('your name')) {
        reply = 'My name is Vocax, your personal voice assistant.';
      } else {
        reply = 'I heard you say: $words';
      }

      await _tts.speak(reply);

      if (!mounted) return;

      setState(() {
        _speaking = false;
        _status = 'Response complete. Tap to try again.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _speaking = false;
        _listening = false;
        _status = 'Could not respond: $error';
      });
    } finally {
      _responding = false;
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _listening = false;
        _status = 'Listening stopped.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _listening = false;
        _status = 'Could not stop listening: $error';
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.0,
            colors: [Color(0xFF0B1630), kBackground],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Vocax',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatusOrb(
                            listening: _listening,
                            speaking: _speaking,
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Your voice. Your world.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          if (_recognizedText.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: kSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: kBlue.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'I heard:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _recognizedText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                GradientButton(
                  label: _busy
                      ? 'Please wait...'
                      : _listening
                          ? 'Stop Listening'
                          : 'Start Listening',
                  leadingIcon: _listening
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  onPressed: _busy
                      ? null
                      : _listening
                          ? _stopListening
                          : _startListening,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Listening lasts up to 30 seconds per session.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const CopyrightFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voice status orb
// ---------------------------------------------------------------------------
class _StatusOrb extends StatelessWidget {
  const _StatusOrb({
    required this.listening,
    required this.speaking,
  });

  final bool listening;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final active = listening || speaking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBlue.withValues(alpha: active ? 0.35 : 0.15),
            kViolet.withValues(alpha: active ? 0.35 : 0.15),
          ],
        ),
        border: Border.all(
          color: kBlue.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: kViolet.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: Icon(
        listening
            ? Icons.graphic_eq_rounded
            : speaking
                ? Icons.volume_up_rounded
                : Icons.mic_none_rounded,
        size: 72,
        color: Colors.white,
      ),
    );
  }
}