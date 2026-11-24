import 'package:flutter/services.dart';

class EqualizerPreset {
  const EqualizerPreset(this.name, this.levels, {this.bassBoost = false});
  final String name;
  final List<double> levels;
  final bool bassBoost;
}



class EqualizerService {
  static const _channel = MethodChannel('soniq/native');
  bool _available = false;
  int? _sessionId;
  bool get available => _available;
  String? lastError;

  static const referenceFrequencies = [60.0, 230.0, 910.0, 3600.0, 14000.0];
  static const referenceLabels = ['60 Hz', '230 Hz', '910 Hz', '3,6 kHz', '14 kHz'];

  static const presets = [
    EqualizerPreset('Normal', [.5, .5, .5, .5, .5]),
    EqualizerPreset('Rock', [.68, .58, .44, .6, .68]),
    EqualizerPreset('Pop', [.44, .58, .64, .58, .46]),
    EqualizerPreset('Eletrônica', [.7, .6, .5, .6, .7]),
    EqualizerPreset('Vocal', [.4, .5, .68, .66, .5]),
    EqualizerPreset('Bass Boost', [.8, .66, .5, .5, .5], bassBoost: true),
  ];

  Future<void> init(int? sessionId) async {
    if (sessionId == _sessionId && _available) return;
    _sessionId = sessionId;
    try {
      _available = await _channel.invokeMethod<bool>('eqAttach', sessionId) ?? false;
      lastError = null;
    } catch (error) {
      _available = false;
      lastError = error.toString();
    }
  }

  Future<void> apply({required bool enabled, required List<double> levels,
    required bool bassBoost, required double bassStrength}) async {
    if (!_available) throw StateError('Sessão de áudio indisponível.');
    await _channel.invokeMethod<void>('eqApply', {
      'enabled': enabled, 'levels': levels, 'bassBoost': bassBoost, 'bassStrength': bassStrength,
    });
  }

  Future<void> dispose() async {
    try { await _channel.invokeMethod<void>('eqAttach', null); } catch (_) {}
  }
}
