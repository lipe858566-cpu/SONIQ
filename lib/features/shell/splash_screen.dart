import 'package:flutter/material.dart';

import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import 'soniq_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1050))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1550), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SoniqShell()));
    });
  }

  @override
  void dispose() { _intro.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => NeonScaffold(
    child: Center(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _intro, curve: Curves.easeInOut),
        child: ScaleTransition(
          scale: Tween(begin: .83, end: 1.0).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutBack)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 210, height: 210,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: SoniqColors.purple.withOpacity(.34), blurRadius: 54)]),
              child: Image.asset('assets/branding/soniq_logo.png'),
            ),
            const SizedBox(height: 22),
            const Text('Música sem limites', style: TextStyle(letterSpacing: 2, color: SoniqColors.muted, fontSize: 13)),
            const SizedBox(height: 34),
            const SizedBox(width: 23, height: 23, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
        ),
      ),
    ),
  );
}
