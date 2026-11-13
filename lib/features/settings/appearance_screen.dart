import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(child: Column(children: [
      const PageTitle('Aparência'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(19, 7, 19, 35), children: [
        const SectionTitle('Tema'),
        Row(children: [
          _ThemeOption(label: 'Claro', icon: Icons.wb_sunny_outlined, mode: ThemeMode.light),
          const SizedBox(width: 10),
          _ThemeOption(label: 'Escuro', icon: Icons.dark_mode_outlined, mode: ThemeMode.dark),
          const SizedBox(width: 10),
          _ThemeOption(label: 'Sistema', icon: Icons.settings_brightness_outlined, mode: ThemeMode.system),
        ]),
        const SizedBox(height: 27),
        const SectionTitle('Cor de destaque'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final color in SoniqColors.accents)
            GestureDetector(
              onTap: () => state.updateAppearance(color: color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 39, height: 39,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color,
                  border: Border.all(color: state.accent.value == color.value ? Colors.white : Colors.transparent, width: 2),
                  boxShadow: state.accent.value == color.value ? [BoxShadow(color: color.withOpacity(.65), blurRadius: 17)] : null),
                child: state.accent.value == color.value ? const Icon(Icons.check_rounded, color: Colors.white) : null,
              ),
            ),
        ]),
        const SizedBox(height: 31),
        const SectionTitle('Plano de fundo'),
        SizedBox(height: 174, child: Row(children: [
          _WallpaperOption(index: 0, child: const _WavePreview()),
          const SizedBox(width: 9),
          _WallpaperOption(index: 1, child: Image.asset('assets/wallpapers/ocean.jpg', fit: BoxFit.cover)),
          const SizedBox(width: 9),
          _WallpaperOption(index: 2, child: Image.asset('assets/wallpapers/nebula.jpg', fit: BoxFit.cover)),
          const SizedBox(width: 9),
          _WallpaperOption(index: 3, child: Image.asset('assets/wallpapers/sunset.jpg', fit: BoxFit.cover)),
          const SizedBox(width: 9),
          Expanded(child: GlassPanel(
            padding: EdgeInsets.zero,
            onTap: () => showDemoMessage(context, 'Planos de fundo personalizados serão adicionados futuramente.'),
            child: const Center(child: Icon(Icons.add_rounded, size: 27)),
          )),
        ])),
        const SizedBox(height: 34),
        const SectionTitle('Transparência da barra inferior'),
        Row(children: [
          Expanded(child: Slider(value: state.navTransparency, onChanged: (v) => state.updateAppearance(transparency: v))),
          SizedBox(width: 48, child: Text('${(state.navTransparency * 100).round()}%', textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 9),
        const Text('A alteração é aplicada imediatamente na navegação do aplicativo.',
          style: TextStyle(fontSize: 11, color: SoniqColors.muted)),
      ])),
    ]));
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.label, required this.icon, required this.mode});
  final String label;
  final IconData icon;
  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final active = state.themeMode == mode;
    return Expanded(child: GlassPanel(
      radius: 13, padding: const EdgeInsets.symmetric(vertical: 15),
      borderOpacity: active ? .95 : .20,
      glow: active,
      onTap: () => state.updateAppearance(mode: mode),
      child: Column(children: [
        Icon(icon, size: 23, color: active ? state.accent : null),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ));
  }
}

class _WallpaperOption extends StatelessWidget {
  const _WallpaperOption({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final selected = state.wallpaperIndex == index;
    return Expanded(child: GestureDetector(
      onTap: () => state.updateAppearance(wallpaper: index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? state.accent : Colors.white12, width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: state.accent.withOpacity(.42), blurRadius: 14)] : null),
        child: ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox.expand(child: child)),
      ),
    ));
  }
}

class _WavePreview extends StatelessWidget {
  const _WavePreview();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF130627), Color(0xFF080611), Color(0xFF6D04C7)])),
    child: Center(child: Icon(Icons.waves_rounded, color: SoniqScope.of(context).accent, size: 32)),
  );
}
