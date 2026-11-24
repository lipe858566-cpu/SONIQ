import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/soniq_theme.dart';
import 'soniq_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.initialization});
  final Future<void> initialization;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this,
    duration: const Duration(seconds: 3))..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.initialization;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const SoniqShell(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ));
    });
  }

  @override
  void dispose() { _motion.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF090613),
    body: SafeArea(child: Stack(fit: StackFit.expand, children: [
      RepaintBoundary(child: CustomPaint(painter: _SoundWaves(_motion))),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TweenAnimationBuilder<double>(tween: Tween(begin: .85, end: 1),
          duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Image.asset('assets/branding/soniq_logo.png', width: 156, height: 156)),
        const SizedBox(height: 24),
        const Text('Música sem limites', style: TextStyle(color: Colors.white70, letterSpacing: 2)),
        const SizedBox(height: 32),
        const SizedBox(width: 100, child: LinearProgressIndicator(minHeight: 3, color: SoniqColors.cyan)),
        const SizedBox(height: 12),
        const Text('Preparando sua experiência', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
      const Positioned(bottom: 24, left: 0, right: 0, child: Text('SONIQ 1.1',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, letterSpacing: 3))),
    ])),
  );
}

class _SoundWaves extends CustomPainter {
  _SoundWaves(this.motion) : super(repaint: motion);
  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .65;
    canvas.drawCircle(center, radius, Paint()..shader = RadialGradient(colors: [
      const Color(0xFF502090).withOpacity(.4), Colors.transparent,
    ]).createShader(Rect.fromCircle(center: center, radius: radius)));
    for (var i = 0; i < 7; i++) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 4) {
        final y = size.height * .5 + math.sin(x / size.width * 7 + motion.value * math.pi * 2 + i * .35) * (28 + i * 9);
        if (x == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
      }
      canvas.drawPath(path, Paint()..color = (i.isEven ? SoniqColors.cyan : SoniqColors.purple).withOpacity(.22)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }
  @override
  bool shouldRepaint(covariant _SoundWaves oldDelegate) => oldDelegate.motion != motion;
}
