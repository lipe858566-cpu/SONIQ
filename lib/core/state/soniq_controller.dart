import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../audio/audio_engine.dart';
import '../audio/download_store.dart';
import '../audio/equalizer_service.dart';
import '../data/catalog_collections.dart';
import '../models/music_models.dart';
import '../services/catalog_repository.dart';
import '../services/music_repository.dart';
import '../theme/soniq_theme.dart';

class SoniqController extends ChangeNotifier {
  SoniqController({MusicRepository? repository, AudioEngine? engine})
      : _repository = repository ?? CatalogRepository(),
        engine = engine ?? AudioEngine() {
    _bindPlayer();
  }

  final MusicRepository _repository;
  final AudioEngine engine;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _equalizerDebounce;
  Future<void> _equalizerOperations = Future<void>.value();
  String? equalizerError;
  bool _queueLoaded = false;

  bool catalogLoading = false;
  String? catalogError;
  String? playbackError;
  bool isBuffering = false;
  Duration? actualDuration;
  bool get hasAudioEngine => true;
  bool get hasRealCatalog => tracks.any((track) => track.playable);
  bool get equalizerAvailable => engine.equalizerService?.available ?? false;

  final List<Track> tracks = [];
  final List<MusicPlaylist> playlists = List.of(CatalogCollections.playlists);
  final Set<String> favorites = {};
  final List<String> queue = [];

  String displayName = 'Ouvinte SONIQ';
  String username = '@soniq';
  String bio = '';
  String? avatarPath;
  int avatarVersion = 0;
  bool profileSaving = false;
  String activeTrackId = '';
  String? recentTrackId;
  Track? get recentTrack => recentTrackId == null ? null : trackById(recentTrackId!);
  Future<void> recordHistory() async {
    final user = currentUser;
    if (user == null || !_isCatalogId(activeTrackId)) return;
    recentTrackId = activeTrackId;
    notifyListeners();
    try {
      await Supabase.instance.client.from('playback_history').upsert({'user_id': user.id, 'track_id': activeTrackId, 'played_at': DateTime.now().toUtc().toIso8601String()});
    } catch (error) { debugPrint('Histórico: $error'); }
  }
  bool playing = false;
  bool shuffle = false;
  int repeatMode = 0;
  bool get repeat => repeatMode != 0;
  int selectedTab = 0;
  int wallpaperIndex = 0;
  double navTransparency = .60;
  ThemeMode themeMode = ThemeMode.dark;
  Color accent = SoniqColors.purple;

  bool equalizerEnabled = false;
  bool bassBoost = false;
  double bassStrength = .60;
  String equalizerPreset = 'Normal';
  List<double> eqLevels = List.of(EqualizerService.presets.first.levels);

  Track get activeTrack => tracks.firstWhere((track) => track.id == activeTrackId, orElse: () => const Track(id: '', title: 'Nenhuma música selecionada', artist: '', duration: '0:00', cover: 'assets/covers/focus.jpg', genre: ''));
  List<Track> get queueTracks => queue.map(trackById).whereType<Track>().toList();
  List<Track> get favoriteTracks => tracks.where((track) => favorites.contains(track.id)).toList();
  bool get hasActivePlayback => _queueLoaded && activeTrack.playable;

  Track? trackById(String id) => tracks.where((track) => track.id == id).firstOrNull;

  String? get avatarUrl {
    final path = avatarPath;
    if (path == null || path.isEmpty || currentUser == null) return null;
    final base = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
    return '$base?v=$avatarVersion';
  }

  void _bindPlayer() {
    final player = engine.player;
    _subscriptions.addAll([
      player.androidAudioSessionIdStream.listen((_) { unawaited(_retryEqualizer()); }),
      player.playerStateStream.listen((state) {
        final buffering = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        if (state.playing && state.processingState == ProcessingState.ready && recentTrackId != activeTrackId) unawaited(recordHistory());
        if (state.playing == playing && buffering == isBuffering) return;
        playing = state.playing;

        isBuffering = buffering;
        notifyListeners();
      }),
      player.currentIndexStream.listen((index) {
        if (index == null || index < 0 || index >= queue.length) return;
        if (activeTrackId == queue[index]) return;
        activeTrackId = queue[index];
        if (playing) unawaited(recordHistory());
        actualDuration = null;
        notifyListeners();
      }),
      player.durationStream.listen((duration) {
        actualDuration = duration;
        notifyListeners();
      }),
      player.playbackEventStream.listen((_) {}, onError: (Object error, StackTrace _) {
        playbackError = 'Não foi possível reproduzir esta faixa. Toque em tentar novamente.';
        isBuffering = false;
        notifyListeners();
      }),
    ]);
  }

  Future<void> initializeEngine() async {
    try {
      await engine.init();
    } catch (error) {
      debugPrint('Falha ao iniciar o motor de áudio: $error');
    }
    await _applyEqualizer(persist: false);
    notifyListeners();
  }

  Future<void> restorePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      wallpaperIndex = prefs.getInt('wallpaperIndex') ?? wallpaperIndex;
      navTransparency = prefs.getDouble('navTransparency') ?? navTransparency;
      final mode = prefs.getInt('themeMode') ?? 2;
      themeMode = ThemeMode.values[mode.clamp(0, 2).toInt()];
      accent = Color(prefs.getInt('accent') ?? accent.value);
      equalizerEnabled = prefs.getBool('eqEnabled') ?? equalizerEnabled;
      bassBoost = prefs.getBool('bassBoost') ?? bassBoost;
      bassStrength = prefs.getDouble('bassStrength') ?? bassStrength;
      equalizerPreset = prefs.getString('eqPreset') ?? equalizerPreset;
      final savedLevels = prefs.getStringList('eqLevels')?.map(double.tryParse).toList();
      if (savedLevels != null && savedLevels.length == eqLevels.length && !savedLevels.contains(null)) {
        eqLevels = savedLevels.whereType<double>().toList();
      }
    } catch (error) {
      debugPrint('Falha ao restaurar preferências: $error');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('wallpaperIndex', wallpaperIndex);
      await prefs.setDouble('navTransparency', navTransparency);
      await prefs.setInt('themeMode', themeMode.index);
      await prefs.setInt('accent', accent.value);
    } catch (error) {
      debugPrint('Falha ao salvar preferências: $error');
    }
  }

  Future<void> _persistEqualizer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('eqEnabled', equalizerEnabled);
      await prefs.setBool('bassBoost', bassBoost);
      await prefs.setDouble('bassStrength', bassStrength);
      await prefs.setString('eqPreset', equalizerPreset);
      await prefs.setStringList('eqLevels', eqLevels.map((v) => v.toString()).toList());
    } catch (error) {
      debugPrint('Falha ao salvar equalizador: $error');
    }
  }

  static final _uuidPattern = RegExp(r'^[0-9a-fA-F-]{36}$');
  static bool _isCatalogId(String id) => _uuidPattern.hasMatch(id);

  void _upsertTrack(Track track) {
    final index = tracks.indexWhere((existing) => existing.id == track.id);
    if (index >= 0) {
      tracks[index] = track;
    } else {
      tracks.add(track);
    }
  }

  Future<void> initializeCatalog() async {
    if (!BackendConfiguration.hasSupabase) {
      catalogError = 'Configure SUPABASE_URL e SUPABASE_ANON_KEY para carregar o catálogo.';
      notifyListeners();
      return;
    }
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      try { for (final track in await DownloadStore.instance.restore()) { _upsertTrack(track); } } catch (_) {}
      final latest = await _repository.trending();
      if (latest.isEmpty) {
        catalogError = 'O catálogo ainda não tem músicas publicadas.';
      } else {
        for (final track in latest.reversed) {
          tracks.removeWhere((existing) => existing.id == track.id);
          tracks.insert(0, track);
        }
        if (!_queueLoaded) {
          queue..clear()..addAll(latest.map((track) => track.id));
          activeTrackId = '';
        }
      }
      await _refreshSavedTracks();
    } catch (error) {
      debugPrint('Falha ao carregar o catálogo: $error');
      catalogError = 'Não foi possível carregar o catálogo. Verifique a conexão e tente novamente.';
    } finally {
      catalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSavedTracks() async {
    final stale = <String>{
      ...favorites,
      if (recentTrackId != null) recentTrackId!,
      for (final playlist in playlists) ...playlist.trackIds,
    }.where((id) => _isCatalogId(id) && trackById(id)?.playable != true).toList();
    if (stale.isEmpty) return;
    for (final track in await _repository.byIds(stale)) {
      _upsertTrack(track);
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    final results = await _repository.search(query);
    for (final track in results) {
      _upsertTrack(track);
    }
    notifyListeners();
    return results;
  }

  void setTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  Future<void> selectTrack(Track track) async {
    if (!track.playable) {
      playbackError = 'O áudio desta faixa está indisponível.';
      activeTrackId = track.id;
      notifyListeners();
      return;
    }
    _upsertTrack(track);
    if (!queue.contains(track.id)) {
      queue.add(track.id);
      if (_queueLoaded) await engine.add(track);
    }
    activeTrackId = track.id;
    playbackError = null;
    notifyListeners();
    await _playActive();
  }

  Future<void> enqueue(Track track) async {
    if (!track.playable || queue.contains(track.id)) return;
    _upsertTrack(track);
    queue.add(track.id);
    if (_queueLoaded) await engine.add(track);
    notifyListeners();
  }

  Future<void> playAll(List<Track> list, {int startIndex = 0}) async {
    final playable = list.where((track) => track.playable).toList();
    if (playable.isEmpty) return;
    for (final track in playable) {
      _upsertTrack(track);
    }
    queue..clear()..addAll(playable.map((track) => track.id));
    _queueLoaded = false;
    activeTrackId = playable[startIndex.clamp(0, playable.length - 1)].id;
    playbackError = null;
    notifyListeners();
    await _playActive();
  }

  Future<void> _playActive() async {
    try {
      final index = queue.indexOf(activeTrackId);
      if (index < 0) return;
      if (!_queueLoaded) {
        await engine.setQueue(queueTracks, index);
        _queueLoaded = true;
        await engine.setShuffle(shuffle);
        await engine.setLoop(_loopMode);
      } else {
        await engine.seekToIndex(index);
      }
      unawaited(engine.play());
      unawaited(_retryEqualizer());
    } catch (error) {
      debugPrint('Falha ao iniciar a reprodução: $error');
      playbackError = 'Não foi possível reproduzir esta faixa. Toque em tentar novamente.';
      isBuffering = false;
      notifyListeners();
    }
  }

  Future<void> retryPlayback() async {
    playbackError = null;
    final position = engine.player.position;
    notifyListeners();
    try {
      final ids = List<String>.of(queue);
      for (final track in await _repository.byIds(ids)) {
        _upsertTrack(track);
      }
      final playable = queueTracks.where((track) => track.playable).toList();
      queue..clear()..addAll(playable.map((track) => track.id));
      if (playable.isEmpty) return;
      final index = playable.indexWhere((track) => track.id == activeTrackId).clamp(0, playable.length - 1);
      await engine.setQueue(playable, index, position: position);
      _queueLoaded = true;
      unawaited(engine.play());
    } catch (error) {
      debugPrint('Falha ao tentar novamente: $error');
      playbackError = 'Não foi possível reproduzir esta faixa. Verifique a conexão.';
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (!activeTrack.playable) return;
    if (!_queueLoaded) {
      await _playActive();
    } else if (playing) {
      await engine.pause();
    } else {
      await engine.play();
    }
  }

  Future<void> seekTo(Duration position) => engine.seek(position);

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
    unawaited(engine.setShuffle(shuffle));
  }

  LoopMode get _loopMode => switch (repeatMode) {
        1 => LoopMode.all,
        2 => LoopMode.one,
        _ => LoopMode.off,
      };

  void toggleRepeat() {
    repeatMode = (repeatMode + 1) % 3;
    notifyListeners();
    unawaited(engine.setLoop(_loopMode));
  }

  Future<void> nextTrack() async {
    if (!_queueLoaded) return;
    await engine.next();
  }

  Future<void> previousTrack() async {
    if (!_queueLoaded) return;
    if (engine.player.position > const Duration(seconds: 3)) {
      await engine.seek(Duration.zero);
    } else {
      await engine.previous();
    }
  }

  void toggleFavorite(String id) {
    if (!favorites.add(id)) favorites.remove(id);
    notifyListeners();
    _persist();
    unawaited(_syncFavorite(id));
  }

  Future<void> _syncFavorite(String id) async {
    final user = currentUser;
    if (user == null) return;
    try {
      if (favorites.contains(id)) {
        await Supabase.instance.client.from('favorites').upsert({
          'user_id': user.id, 'track_id': id,
        }, onConflict: 'user_id,track_id');
      } else {
        await Supabase.instance.client.from('favorites').delete()
            .eq('user_id', user.id).eq('track_id', id);
      }
    } catch (error) {
      debugPrint('Falha ao sincronizar favorito: $error');
    }
  }

  Future<void> addPlaylist(String name, {List<String> trackIds = const []}) async {
    final user = currentUser;
    if (user == null) throw StateError('Entre na sua conta.');
    final db = Supabase.instance.client;
    final row = await db.from('playlists').insert({'user_id': user.id, 'name': name}).select('id').single();
    final id = row['id'] as String;
    final ids = trackIds.where(_isCatalogId).toSet().toList();
    try {
      if (ids.isNotEmpty) await db.from('playlist_tracks').insert([for (var i = 0; i < ids.length; i++) {'playlist_id': id, 'track_id': ids[i], 'position': i}]);
    } catch (_) {
      await db.from('playlists').delete().eq('id', id);
      rethrow;
    }
    playlists.add(MusicPlaylist(id: id, title: name, cover: 'assets/covers/focus.jpg', trackIds: ids));
    notifyListeners();
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final playlist = playlists.where((item) => item.id == playlistId).firstOrNull;
    if (playlist == null || !_isCatalogId(playlistId) || playlist.trackIds.contains(trackId)) return;
    await Supabase.instance.client.from('playlist_tracks').insert({'playlist_id': playlistId, 'track_id': trackId, 'position': playlist.trackIds.length});
    playlist.trackIds.add(trackId);
    notifyListeners();
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final playlist = playlists.where((item) => item.id == playlistId).firstOrNull;
    if (playlist == null || !_isCatalogId(playlistId)) return;
    await Supabase.instance.client.from('playlist_tracks').delete().eq('playlist_id', playlistId).eq('track_id', trackId);
    playlist.trackIds.remove(trackId);
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    final user = currentUser;
    if (user == null || !_isCatalogId(playlistId)) return;
    await Supabase.instance.client.from('playlists').delete().eq('id', playlistId).eq('user_id', user.id).select('id').single();
    playlists.removeWhere((item) => item.id == playlistId);
    notifyListeners();
  }

  bool isPersonalPlaylist(String id) => _isCatalogId(id);

  Future<void> loadPlaylists() async {
    final user = currentUser;
    if (user == null) return;
    final rows = await Supabase.instance.client.from('playlists').select('id,name,playlist_tracks(track_id,position)').eq('user_id', user.id);
    playlists.removeWhere((p) => _isCatalogId(p.id));
    for (final row in rows) {
      final entries = List<Map<String, dynamic>>.from(row['playlist_tracks'] as List)..sort((a,b) => (a['position'] as int).compareTo(b['position'] as int));
      playlists.add(MusicPlaylist(id: row['id'] as String, title: row['name'] as String, cover: 'assets/covers/focus.jpg', trackIds: entries.map((e) => e['track_id'] as String).toList()));
    }
  }

  void updateProfile(String name, String handle, String description) {
    displayName = name;
    username = handle;
    bio = description;
    notifyListeners();
    _persist();
  }

  bool get cloudEnabled => BackendConfiguration.hasSupabase;
  User? get currentUser => cloudEnabled ? Supabase.instance.client.auth.currentUser : null;

  Future<void> resetAccount() async {
    await clearQueue();
    tracks.clear();
    favorites.clear();
    playlists.removeWhere((p) => _isCatalogId(p.id));
    recentTrackId = null;
    activeTrackId = '';
    avatarPath = null;
    displayName = 'Ouvinte SONIQ';
    username = '@soniq';
    bio = '';
    notifyListeners();
  }

  Future<void> loadRemoteProfile() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client.from('profiles')
          .select('display_name, username, bio, avatar_path, updated_at')
          .eq('id', user.id).maybeSingle();
      if (currentUser?.id != user.id) return;
      avatarPath = null;
      if (data != null) {
        displayName = data['display_name'] as String? ?? displayName;
        username = data['username'] as String? ?? username;
        bio = data['bio'] as String? ?? bio;
        final path = data['avatar_path'] as String?;
        avatarPath = path;
        if (path != null && path.isNotEmpty) {
          final updated = DateTime.tryParse(data['updated_at'] as String? ?? '');
          avatarVersion = updated?.millisecondsSinceEpoch ?? avatarVersion;
        }
      }
      if (currentUser?.id != user.id) return;
      notifyListeners();
      await loadPlaylists();
      final history = await Supabase.instance.client.from('playback_history').select('track_id').eq('user_id', user.id).order('played_at', ascending: false).limit(1);
      recentTrackId = history.isEmpty ? null : history.first['track_id'] as String;
      final saved = await Supabase.instance.client.from('favorites')
          .select('track_id').eq('user_id', user.id);
      favorites..clear()..addAll(saved.map((item) => item['track_id'] as String));
      notifyListeners();
      await _persist();
      await _refreshSavedTracks();
      notifyListeners();
    } catch (error) {
      debugPrint('Falha ao carregar perfil: $error');
    }
  }

  Future<void> saveProfile(String name, String handle, String description) async {
    profileSaving = true;
    notifyListeners();
    try {
      final user = currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id, 'display_name': name,
          'username': handle, 'bio': description,
        }, onConflict: 'id');
      }
      updateProfile(name, handle, description);
    } finally {
      profileSaving = false;
      notifyListeners();
    }
  }


  Future<void> uploadAvatar(Uint8List bytes, String extension) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta para sincronizar sua foto.');
    }
    final ext = extension.toLowerCase() == 'png' ? 'png' : 'jpg';
    final now = DateTime.now();
    final path = '${user.id}/avatar_${now.millisecondsSinceEpoch}.$ext';
    final storage = Supabase.instance.client.storage.from('avatars');
    await storage.uploadBinary(
      path, bytes,
      fileOptions: FileOptions(upsert: true, contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
    );
    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'avatar_path': path,
      'updated_at': now.toUtc().toIso8601String(),
    }, onConflict: 'id');
    final previous = avatarPath;
    avatarPath = path;
    avatarVersion = now.millisecondsSinceEpoch;
    notifyListeners();
    await _persist();
    if (previous != null && previous != path && previous.startsWith('${user.id}/')) {
      try {
        await storage.remove([previous]);
      } catch (error) {
        debugPrint('Falha ao remover avatar anterior: $error');
      }
    }
  }

  Future<void> removeAvatar() async {
    final user = currentUser;
    if (user == null) return;
    final previous = avatarPath;
    await Supabase.instance.client.from('profiles').update({
      'avatar_path': null, 'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
    avatarPath = null;
    avatarVersion++;
    notifyListeners();
    if (previous != null && previous.startsWith('${user.id}/')) {
      try { await Supabase.instance.client.storage.from('avatars').remove([previous]); }
      catch (error) { debugPrint('Falha ao limpar avatar: $error'); }
    }
  }

  void updateAppearance({ThemeMode? mode, Color? color, int? wallpaper, double? transparency}) {
    if (mode != null) themeMode = mode;
    if (color != null) accent = color;
    if (wallpaper != null) wallpaperIndex = wallpaper;
    if (transparency != null) navTransparency = transparency;
    notifyListeners();
    _persist();
  }

  Future<void> _retryEqualizer() async {
    await engine.equalizerService?.init(engine.player.androidAudioSessionId);
    notifyListeners();
    await _applyEqualizer(persist: false);
  }

  Future<void> _applyEqualizer({bool persist = true}) async {

    _equalizerOperations = _equalizerOperations.catchError((Object _) {}).then((_) async {
      try {
        final service = engine.equalizerService;
        if (service == null || !service.available) {
          equalizerError = null;
          notifyListeners();
          return;
        }
        await service.apply(
          enabled: equalizerEnabled,
          levels: List<double>.of(eqLevels),
          bassBoost: bassBoost,
          bassStrength: bassStrength,
        );
        equalizerError = null;
      } catch (error) {
        equalizerError = 'Não foi possível aplicar o equalizador neste aparelho.';
        debugPrint('Falha ao aplicar equalizador: $error');
      }
      notifyListeners();
    });
    await _equalizerOperations;
    if (persist) await _persistEqualizer();
  }

  void _scheduleEqualizer() {
    notifyListeners();
    _equalizerDebounce?.cancel();
    _equalizerDebounce = Timer(const Duration(milliseconds: 60), _applyEqualizer);
  }

  void updateBand(int index, double value) {
    eqLevels = List.of(eqLevels)..[index] = value;
    equalizerPreset = 'Personalizado';
    _scheduleEqualizer();
  }

  void updateBandGroup(List<int> indexes, double value) {
    eqLevels = List.of(eqLevels);
    for (final index in indexes) {
      eqLevels[index] = value;
    }
    equalizerPreset = 'Personalizado';
    _scheduleEqualizer();
  }

  void updateBass(double value) { bassStrength = value; _scheduleEqualizer(); }
  void toggleEqualizer(bool value) { equalizerEnabled = value; _scheduleEqualizer(); }
  void toggleBass(bool value) { bassBoost = value; _scheduleEqualizer(); }

  void setPreset(String name) {
    final preset = EqualizerService.presets.where((item) => item.name == name).firstOrNull;
    if (preset == null) return;
    equalizerPreset = name;
    eqLevels = List.of(preset.levels);
    bassBoost = preset.bassBoost;
    equalizerEnabled = true;
    _scheduleEqualizer();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    if (_queueLoaded) unawaited(engine.move(oldIndex, newIndex));
    notifyListeners();
  }

  Future<void> removeFromQueue(String id) async {
    final index = queue.indexOf(id);
    if (index < 0) return;
    if (id == activeTrackId && queue.length == 1) {
      await clearQueue();
      return;
    }
    queue.removeAt(index);
    if (_queueLoaded) await engine.removeAt(index);
    notifyListeners();
  }

  Future<void> clearQueue() async {
    queue.clear();
    _queueLoaded = false;
    playing = false;
    notifyListeners();
    await engine.clear();
  }

  @override
  void dispose() {
    _equalizerDebounce?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    engine.dispose();
    super.dispose();
  }
}

class SoniqScope extends InheritedNotifier<SoniqController> {
  const SoniqScope({super.key, required SoniqController controller, required super.child}) : super(notifier: controller);

  static SoniqController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SoniqScope>();
    assert(scope != null, 'SoniqScope must wrap the application.');
    return scope!.notifier!;
  }
}
