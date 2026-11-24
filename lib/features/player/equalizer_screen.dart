import 'package:flutter/material.dart';

import '../../core/audio/equalizer_service.dart';
import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  static double _average(List<double> levels, List<int> indexes) =>
      indexes.map((i) => levels[i]).reduce((a, b) => a + b) / indexes.length;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final enabled = state.equalizerEnabled;
    return NeonScaffold(child: Column(children: [
      PageTitle('Equalizador', actions: [
        Switch(
          value: state.equalizerEnabled,
          onChanged: state.toggleEqualizer,
        ),
      ]),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(19, 5, 19, 30), children: [
        if (!state.equalizerAvailable) const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('Inicie uma música para conectar os efeitos à sessão de áudio. Se o aparelho não oferecer suporte, os ajustes serão apenas salvos.',
              style: TextStyle(fontSize: 12, color: Color(0xFFFFB1C6))),
        ),
        if (state.equalizerError != null) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(state.equalizerError!, style: const TextStyle(color: Color(0xFFFFB1C6), fontSize: 12)),
        ),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final preset in EqualizerService.presets)
            Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(
              label: Text(preset.name, style: const TextStyle(fontSize: 11)),
              selected: state.equalizerPreset == preset.name,
              selectedColor: state.accent,
              onSelected: (_) => state.setPreset(preset.name),
              side: BorderSide(color: state.accent.withOpacity(.25)),
            )),
          if (state.equalizerPreset == 'Personalizado') Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: const Text('Personalizado', style: TextStyle(fontSize: 11)),
              selected: true,
              selectedColor: state.accent,
              onSelected: (_) {},
            ),
          ),
        ])),
        const SizedBox(height: 20),
        _GroupSlider(label: 'Graves', value: _average(state.eqLevels, const [0, 1]), enabled: enabled,
            onChanged: (v) => state.updateBandGroup(const [0, 1], v)),
        const SizedBox(height: 10),
        _GroupSlider(label: 'Médios', value: _average(state.eqLevels, const [2]), enabled: enabled,
            onChanged: (v) => state.updateBandGroup(const [2], v)),
        const SizedBox(height: 10),
        _GroupSlider(label: 'Agudos', value: _average(state.eqLevels, const [3, 4]), enabled: enabled,
            onChanged: (v) => state.updateBandGroup(const [3, 4], v)),
        const SizedBox(height: 22),
        const Text('Bandas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(height: 240, child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < EqualizerService.referenceLabels.length; i++)
            Expanded(child: Column(children: [
              Expanded(child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: state.eqLevels[i],
                  onChanged: enabled ? (value) => state.updateBand(i, value) : null,
                ),
              )),
              const SizedBox(height: 6),
              Text(EqualizerService.referenceLabels[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ])),
        ])),
        const SizedBox(height: 20),
        GlassPanel(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Column(children: [
          Row(children: [
            const Expanded(child: Text('Bass Boost', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            Switch(value: state.bassBoost, onChanged: enabled ? state.toggleBass : null),
          ]),
          Row(children: [
            Expanded(child: Slider(
              value: state.bassStrength,
              onChanged: enabled && state.bassBoost ? state.updateBass : null,
            )),
            Text('${(state.bassStrength * 100).round()}%', style: const TextStyle(fontSize: 11)),
          ]),
        ])),
        const SizedBox(height: 14),
        Text(state.equalizerAvailable ? 'Efeitos conectados à sessão de áudio.' : 'Efeitos ainda não conectados. Preferências salvas.',
            style: TextStyle(fontSize: 11, color: SoniqColors.muted)),
      ])),
    ]));
  }
}

class _GroupSlider extends StatelessWidget {
  const _GroupSlider({required this.label, required this.value, required this.enabled, required this.onChanged});
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final decibels = (value - .5) * 30;
    return GlassPanel(padding: const EdgeInsets.fromLTRB(12, 6, 12, 6), child: Row(children: [
      SizedBox(width: 62, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      Expanded(child: Slider(value: value, onChanged: enabled ? onChanged : null)),
      SizedBox(width: 44, child: Text('${decibels >= 0 ? '+' : ''}${decibels.round()} dB',
          textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
    ]));
  }
}
