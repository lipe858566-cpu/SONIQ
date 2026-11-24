import 'package:flutter_test/flutter_test.dart';
import 'package:soniq/core/audio/equalizer_service.dart';
import 'package:soniq/core/models/music_models.dart';

void main() {
  group('Track', () {
    const base = Track(id: '1', title: 't', artist: 'a', duration: '3:05', cover: 'c', genre: 'g');

    test('parses duration', () => expect(base.length, const Duration(minutes: 3, seconds: 5)));

    test('is playable only with an audio address', () {
      expect(base.playable, isFalse);
      const withAudio = Track(id: '2', title: 't', artist: 'a', duration: '0:10', cover: 'c', genre: 'g', audioUrl: 'https://example.com/a.mp3');
      expect(withAudio.playable, isTrue);
    });

    test('formats seconds', () => expect(Track.formatSeconds(125), '2:05'));
  });

  group('Equalizer presets', () {
    test('every preset has five levels inside 0..1', () {
      for (final preset in EqualizerService.presets) {
        expect(preset.levels.length, EqualizerService.referenceFrequencies.length);
        expect(preset.levels.every((v) => v >= 0 && v <= 1), isTrue, reason: preset.name);
      }
    });

    test('required presets exist', () {
      final names = EqualizerService.presets.map((p) => p.name);
      expect(names, containsAll(['Normal', 'Rock', 'Pop', 'Eletrônica', 'Vocal', 'Bass Boost']));
    });
  });
}
