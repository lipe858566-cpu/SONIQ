import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/soniq_controller.dart';
import '../theme/soniq_theme.dart';

class NeonScaffold extends StatelessWidget {
  const NeonScaffold({super.key, required this.child, this.bottomNavigationBar});

  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeonBackdrop(),
          SafeArea(bottom: false, child: child),
          if (bottomNavigationBar != null)
            Positioned(left: 14, right: 14, bottom: MediaQuery.of(context).padding.bottom + 8, child: bottomNavigationBar!),
        ],
      ),
    );
  }
}

class NeonBackdrop extends StatefulWidget {
  const NeonBackdrop({super.key});

  @override
  State<NeonBackdrop> createState() => _NeonBackdropState();
}

class _NeonBackdropState extends State<NeonBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this, duration: const Duration(seconds: 13))..repeat();

  @override
  void dispose() { _motion.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = SoniqScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallpaper = settings.wallpaperIndex;
    final image = switch (wallpaper) {
      1 => 'assets/wallpapers/ocean.jpg',
      2 => 'assets/wallpapers/nebula.jpg',
      3 => 'assets/wallpapers/sunset.jpg',
      _ => null,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0A0615), Color(0xFF080611), Color(0xFF100820)]
              : const [Color(0xFFF8F2FF), Color(0xFFEFE6FA), Color(0xFFF5F1FF)],
        ))),
        if (image != null) ...[
          Image.asset(image, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(.33)),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(.35), Colors.black.withOpacity(.85)],
          ))),
        ],
        RepaintBoundary(child: AnimatedBuilder(
          animation: _motion,
          builder: (_, __) => CustomPaint(
            painter: NeonWavesPainter(
              phase: _motion.value * math.pi * 2,
              accent: settings.accent,
              dark: isDark,
            ),
          ),
        )),
      ],
    );
  }
}

class NeonWavesPainter extends CustomPainter {
  const NeonWavesPainter({required this.phase, required this.accent, required this.dark});

  final double phase;
  final Color accent;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader = RadialGradient(colors: [accent.withOpacity(dark ? .20 : .11), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(size.width * .83, size.height * .10), radius: size.width * .73));
    canvas.drawRect(Offset.zero & size, topGlow);

    final lowerGlow = Paint()
      ..shader = RadialGradient(colors: [SoniqColors.cyan.withOpacity(.10), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(size.width * .06, size.height * .90), radius: size.width * .85));
    canvas.drawRect(Offset.zero & size, lowerGlow);

    for (var i = 0; i < 9; i++) {
      final wave = Path();
      for (var x = 0.0; x <= size.width + 5; x += 5) {
        final y = size.height * .09 + i * 3.8 +
            math.sin(x / size.width * math.pi * 2.2 + phase + i * .12) * (12 + i * 1.3) +
            math.sin(x / size.width * math.pi * 3.8 - phase * .38) * 7;
        if (x == 0) { wave.moveTo(x, y); } else { wave.lineTo(x, y); }
      }
      canvas.drawPath(wave, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.3 : .65
        ..color = (i.isEven ? accent : SoniqColors.cyan).withOpacity(dark ? .13 : .09));
    }

    for (var i = 0; i < 8; i++) {
      final wave = Path();
      for (var x = 0.0; x <= size.width + 5; x += 5) {
        final y = size.height * .91 + i * 3 +
            math.sin(x / size.width * math.pi * 2 + phase * .7 + i * .13) * 16;
        if (x == 0) { wave.moveTo(x, y); } else { wave.lineTo(x, y); }
      }
      canvas.drawPath(wave, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = (i.isEven ? accent : SoniqColors.cyan).withOpacity(.15));
    }
  }

  @override
  bool shouldRepaint(covariant NeonWavesPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent || oldDelegate.dark != dark;
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.opacity = .65,
    this.borderOpacity = .22,
    this.glow = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final double borderOpacity;
  final bool glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = SoniqScope.of(context).accent;
    final light = Theme.of(context).brightness == Brightness.light;
    final surface = light ? const Color(0xFFF4ECFF) : const Color(0xFF21152F);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [surface.withOpacity(opacity), (light ? Colors.white : const Color(0xFF0E0B1D)).withOpacity(opacity * .83)],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: accent.withOpacity(borderOpacity)),
            boxShadow: glow ? [BoxShadow(color: accent.withOpacity(.22), blurRadius: 24, spreadRadius: -8)] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({super.key, required this.label, required this.onPressed, this.icon, this.compact = false});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = SoniqScope.of(context).accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [accent, const Color(0xFF7800E8), accent]),
        boxShadow: [BoxShadow(color: accent.withOpacity(.42), blurRadius: 16, spreadRadius: -4)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 19, vertical: compact ? 9 : 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white, size: compact ? 17 : 20), const SizedBox(width: 7)],
                Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: compact ? 12 : 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoverArt extends StatelessWidget {
  static const _coverFallback = DecoratedBox(
    decoration: BoxDecoration(color: SoniqColors.surface),
    child: Icon(Icons.music_note, color: SoniqColors.cyan),
  );

  const CoverArt(this.asset, {super.key, this.size = 56, this.radius = 12, this.fit = BoxFit.cover});

  final String asset;
  final double size;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      width: size,
      height: size,
      child: asset.startsWith('https://')
          ? Image.network(asset, fit: fit, errorBuilder: (_, __, ___) => _coverFallback)
          : Image.asset(asset, fit: fit, errorBuilder: (_, __, ___) => _coverFallback),
    ),
  );
}

class SoniqWaveMark extends StatelessWidget {
  const SoniqWaveMark({super.key, this.size = 29});
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = SoniqScope.of(context).accent;
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final h in [.30, .58, .85, 1.0, .72, .48, .24])
            Container(width: size * .065, height: size * h, decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: color.withOpacity(.75), blurRadius: 6)],
            )),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

class CircleGlassButton extends StatelessWidget {
  const CircleGlassButton({super.key, required this.icon, required this.onTap, this.size = 38, this.active = false});
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: GlassPanel(
      padding: EdgeInsets.zero,
      radius: size / 2,
      onTap: onTap,
      borderOpacity: active ? .7 : .18,
      child: Center(child: Icon(icon, size: size * .52, color: active ? SoniqScope.of(context).accent : null)),
    ),
  );
}

void showDemoMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
  ));
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.actions = const []});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 13, 18, 15),
    child: Row(children: [
      CircleGlassButton(icon: Icons.arrow_back_ios_new_rounded, size: 35, onTap: () => Navigator.maybePop(context)),
      Expanded(child: Center(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
      if (actions.isEmpty) const SizedBox(width: 35) else ...actions,
    ]),
  );
}
