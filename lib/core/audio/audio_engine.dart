import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/music_models.dart';
import 'equalizer_service.dart';
import 'download_store.dart';



class AudioEngine {
  AudioEngine() {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (android) {
      player = AudioPlayer();
      equalizerService = EqualizerService();
    } else {
      player = AudioPlayer();
    }
  }

  late final AudioPlayer player;
  EqualizerService? equalizerService;
  ConcatenatingAudioSource? _queue;

  bool get hasQueue => _queue != null;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await equalizerService?.init(player.androidAudioSessionId);
  }

  Future<AudioSource> _source(Track track) async {
    Uri uri = Uri.parse(track.audioUrl!);
    try { final file = await DownloadStore.instance.fileFor(track.id); if (await file.exists()) uri = file.uri; } catch (_) {}
    return AudioSource.uri(
        uri,
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album.isEmpty ? null : track.album,
          artUri: track.artworkUrl == null ? null : Uri.tryParse(track.artworkUrl!),
          duration: track.length == Duration.zero ? null : track.length,
        ),
      );
  }

  Future<void> setQueue(List<Track> tracks, int startIndex, {Duration position = Duration.zero}) async {
    final source = ConcatenatingAudioSource(children: await Future.wait(tracks.map(_source)));
    _queue = source;
    await player.setAudioSource(source, initialIndex: startIndex, initialPosition: position);
  }

  Future<void> add(Track track) async => _queue?.add(await _source(track));
  Future<void> removeAt(int index) async => _queue?.removeAt(index);
  Future<void> move(int from, int to) async => _queue?.move(from, to);

  Future<void> clear() async {
    await player.stop();
    _queue = null;
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> seekToIndex(int index) => player.seek(Duration.zero, index: index);
  Future<void> next() => player.seekToNext();
  Future<void> previous() => player.seekToPrevious();
  Future<void> setShuffle(bool value) => player.setShuffleModeEnabled(value);
  Future<void> setLoop(LoopMode mode) => player.setLoopMode(mode);

  Future<void> dispose() async {
    await equalizerService?.dispose();
    await player.dispose();
  }
}
