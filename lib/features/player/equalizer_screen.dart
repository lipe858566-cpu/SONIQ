import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  static const frequencies = ['60', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(child: Column(children: [
      PageTitle('Equalizador', actions: [Switch(value: state.equalizerEnabled, onChanged: state.toggleEqualizer)]),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(19, 5, 19, 30), children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final preset in ['Padrão', 'Pop', 'Rock', 'Eletrônica'])
            Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(
              label: Text(preset, style: const TextStyle(fontSize: 11)),
              selected: state.equalizerPreset == preset,
              selectedColor: state.accent,
              onSelected: (_) => state.setPreset(preset),
              side: BorderSide(color: state.accent.withOpacity(.25)),
            )),
        ])),
        const SizedBox(height: 22),
        SizedBox(height: 300, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < frequencies.length; i++)
            Expanded(child: Column(children: [
              Expanded(child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: state.bands[i],
                  min: 0, max: 1,
                  onChanged: state.equalizerEnabled ? (value) => state.updateBand(i, value) : null,
                ),
              )),
              const SizedBox(height: 8),
              Text(frequencies[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              const Text('Hz', style: TextStyle(fontSize: 9, color: SoniqColors.muted)),
            ])),
        ])),
        const SizedBox(height: 25),
        _EffectSlider(
          label: 'Reforço de graves', value: state.bassStrength, enabled: state.bassBoost,
          onToggle: state.toggleBass, onChanged: state.updateBass,
        ),
        const SizedBox(height: 12),
        _EffectSlider(
          label: 'Virtualizador', value: state.virtualizerStrength, enabled: state.virtualizer,
          onToggle: state.toggleVirtualizer, onChanged: state.updateVirtualizer,
        ),
        const SizedBox(height: 18),
        const Text('Controles visuais de demonstração. O processamento de áudio será ativado após integrar um motor compatível.',
          style: TextStyle(fontSize: 11, color: SoniqColors.muted)),
      ])),
    ]));
  }
}

class _EffectSlider extends StatelessWidget {
  const _EffectSlider({required this.label, required this.value, required this.enabled, required this.onToggle, required this.onChanged});
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => GlassPanel(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Column(children: [
    Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      Switch(value: enabled, onChanged: onToggle),
    ]),
    Row(children: [
      Expanded(child: Slider(value: value, onChanged: enabled ? onChanged : null)),
      Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 11)),
    ]),
  ]));
}
