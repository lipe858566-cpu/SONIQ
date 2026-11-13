import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../data/demo_catalog.dart';
import '../models/music_models.dart';
import '../services/youtube_repository.dart';
import '../services/music_repository.dart';
import '../theme/soniq_theme.dart';

class SoniqController extends ChangeNotifier {
  SoniqController({MusicRepository? repository})
      : _repository = repository ?? YouTubeRepository();

  final MusicRepository _repository;
  bool catalogLoading = false;
  String? catalogError;
  String? playbackError;
  bool isBuffering = false;
  Duration? actualDuration;
  bool get hasAudioEngine => false;
  bool get hasRealCatalog => tracks.any((track) => track.playable);

  final List<Track> tracks = List.of(DemoCatalog.tracks);
  final List<MusicPlaylist> playlists = List.of(DemoCatalog.playlists);
  final Set<String> favorites = {'blinding', 'afterhours'};
  final List<String> queue = DemoCatalog.tracks.map((track) => track.id).toList();

  String displayName = 'Felipe Gabriel';
  String username = '@felipegabriel';
  String bio = 'Apaixonado por música 🎧';
  String? avatarUrl;
  bool profileSaving = false;
  String activeTrackId = 'blinding';
  bool playing = false;
  bool shuffle = false;
  bool repeat = false;
  bool backgroundPlayback = true;
  bool equalizerEnabled = true;
  bool bassBoost = true;
  bool virtualizer = true;
  double bassStrength = .60;
  double virtualizerStrength = .40;
  double progress = 0;
  int selectedTab = 0;
  int wallpaperIndex = 0;
  double navTransparency = .60;
  ThemeMode themeMode = ThemeMode.dark;
  Color accent = SoniqColors.purple;
  String equalizerPreset = 'Eletrônica';
  List<double> bands = [.44, .55, .61, .56, .45, .48, .42, .51, .58];

  Track get activeTrack => tracks.firstWhere((track) => track.id == activeTrackId, orElse: () => tracks.first);
  List<Track> get queueTracks => queue.map((id) => tracks.where((track) => track.id == id).firstOrNull).whereType<Track>().toList();
  List<Track> get favoriteTracks => tracks.where((track) => favorites.contains(track.id)).toList();

  Future<void> restorePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      displayName = prefs.getString('displayName') ?? displayName;
      username = prefs.getString('username') ?? username;
      bio = prefs.getString('bio') ?? bio;
      avatarUrl = prefs.getString('avatarUrl');
      wallpaperIndex = prefs.getInt('wallpaperIndex') ?? wallpaperIndex;
      navTransparency = prefs.getDouble('navTransparency') ?? navTransparency;
      final mode = prefs.getInt('themeMode') ?? 2;
      themeMode = ThemeMode.values[mode.clamp(0, 2).toInt()];
      accent = Color(prefs.getInt('accent') ?? accent.value);
      final savedFavorites = prefs.getStringList('favorites');
      if (savedFavorites != null) {
        favorites..clear()..addAll(savedFavorites);
      }
      final savedPlaylists = prefs.getStringList('customPlaylists') ?? [];
      for (var i = 0; i < savedPlaylists.length; i++) {
        final entry = jsonDecode(savedPlaylists[i]) as Map<String, dynamic>;
        playlists.add(MusicPlaylist(
          id: 'custom_$i',
          title: entry['title'] as String,
          cover: 'assets/covers/focus.jpg',
          trackIds: List<String>.from(entry['trackIds'] as List<dynamic>? ?? []),
        ));
      }
    } catch (_) {
      // Defaults keep the visual demo usable if local storage is unavailable.
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', displayName);
      await prefs.setString('username', username);
      await prefs.setString('bio', bio);
      if (avatarUrl != null) await prefs.setString('avatarUrl', avatarUrl!);
      await prefs.setInt('wallpaperIndex', wallpaperIndex);
      await prefs.setDouble('navTransparency', navTransparency);
      await prefs.setInt('themeMode', themeMode.index);
      await prefs.setInt('accent', accent.value);
      await prefs.setStringList('favorites', favorites.toList());
      await prefs.setStringList('customPlaylists', playlists
          .where((p) => p.id.startsWith('custom_'))
          .map((p) => jsonEncode({'title': p.title, 'trackIds': p.trackIds}))
          .toList());
    } catch (_) {
      // Local preferences are optional for the offline demo.
    }
  }

  Future<void> initializeCatalog() async {
    if (BackendConfiguration.youtubeApiKey.isEmpty && !BackendConfiguration.hasSupabase && BackendConfiguration.apiBaseUrl.isEmpty) {
      catalogLoading = false;
      catalogError = 'Configure a API do YouTube ou a função youtube-search do Supabase.';
      notifyListeners();
      return;
    }
    
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      final trending = await _repository.trending();
      if (trending.isEmpty) {
        catalogError = 'Não encontramos resultados no momento.';
      } else {
        for (final track in trending.reversed) {
          tracks.removeWhere((existing) => existing.id == track.id);
          tracks.insert(0, track);
        }
        if (!playing) {
          queue
            ..clear()
            ..addAll(trending.map((track) => track.id));
          activeTrackId = trending.first.id;
          progress = 0;
        } else {
          for (final track in trending) {
            if (!queue.contains(track.id)) queue.add(track.id);
          }
        }
      }
    } catch (error) {
      catalogError = error.toString();
    } finally {
      catalogLoading = false;
      notifyListeners();
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    final results = await _repository.search(query);
    for (final track in results) {
      if (!tracks.any((existing) => existing.id == track.id)) {
        tracks.add(track);
      }
      if (!queue.contains(track.id)) queue.add(track.id);
    }
    notifyListeners();
    return results;
  }

  void setTab(int index) { selectedTab = index; notifyListeners(); }

  void selectTrack(Track track) {
    activeTrackId = track.id;
    progress = 0;
    playbackError = track.playable ? null : 'Esta faixa é ilustrativa. Pesquise uma música na aba Explorar.';
    playing = false;
    if (!queue.contains(track.id)) queue.add(track.id);
    notifyListeners();
  }

  // The embedded YouTube player owns playback, seeking, and its media controls.
  void togglePlay() { notifyListeners(); }
  void setProgress(double value) { progress = value; notifyListeners(); }
  void toggleShuffle() { shuffle = !shuffle; notifyListeners(); }
  void toggleRepeat() { repeat = !repeat; notifyListeners(); }
  void nextTrack() {
    if (queue.isEmpty) return;
    final index = queue.indexOf(activeTrackId);
    final track = tracks.where((item) => item.id == queue[(index + 1) % queue.length]).firstOrNull;
    if (track != null) selectTrack(track);
  }
  void previousTrack() {
    if (queue.isEmpty) return;
    final index = queue.indexOf(activeTrackId);
    final track = tracks.where((item) => item.id == queue[(index - 1 + queue.length) % queue.length]).firstOrNull;
    if (track != null) selectTrack(track);
  }

  void toggleFavorite(String id) {
    if (!favorites.add(id)) favorites.remove(id);
    notifyListeners();
    _persist();
    unawaited(_syncFavorite(id));
  }

  Future<void> _syncFavorite(String id) async {
    final user = currentUser;
    if (user != null) {
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
  }

  void addPlaylist(String name, {List<String> trackIds = const []}) {
    final index = playlists.where((p) => p.id.startsWith('custom_')).length;
    playlists.add(MusicPlaylist(id: 'custom_$index', title: name, cover: 'assets/covers/focus.jpg', trackIds: List.of(trackIds)));
    notifyListeners();
    _persist();
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

  Future<void> loadRemoteProfile() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client.from('profiles')
          .select('display_name, username, bio, avatar_path')
          .eq('id', user.id).maybeSingle();
      if (data == null) return;
      displayName = data['display_name'] as String? ?? displayName;
      username = data['username'] as String? ?? username;
      bio = data['bio'] as String? ?? bio;
      final path = data['avatar_path'] as String?;
      if (path != null && path.isNotEmpty) {
        avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      }
      final saved = await Supabase.instance.client.from('favorites')
          .select('track_id').eq('user_id', user.id);
      favorites..clear()..addAll(saved.map((item) => item['track_id'] as String));
      notifyListeners();
      await _persist();
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
    final path = '${user.id}/profile.$ext';
    await Supabase.instance.client.storage.from('avatars').uploadBinary(
      path, bytes,
      fileOptions: FileOptions(upsert: true, contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
    );
    await Supabase.instance.client.from('profiles')
        .upsert({'id': user.id, 'avatar_path': path}, onConflict: 'id');
    avatarUrl = '${Supabase.instance.client.storage.from('avatars').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
    await _persist();
  }

  void updateAppearance({ThemeMode? mode, Color? color, int? wallpaper, double? transparency}) {
    if (mode != null) themeMode = mode;
    if (color != null) accent = color;
    if (wallpaper != null) wallpaperIndex = wallpaper;
    if (transparency != null) navTransparency = transparency;
    notifyListeners();
    _persist();
  }

  void updateBand(int index, double value) { bands[index] = value; equalizerPreset = 'Personalizado'; notifyListeners(); }
  void updateBass(double value) { bassStrength = value; notifyListeners(); }
  void updateVirtualizer(double value) { virtualizerStrength = value; notifyListeners(); }
  void toggleEqualizer(bool value) { equalizerEnabled = value; notifyListeners(); }
  void toggleBass(bool value) { bassBoost = value; notifyListeners(); }
  void toggleVirtualizer(bool value) { virtualizer = value; notifyListeners(); }
  void toggleBackgroundPlayback(bool value) { backgroundPlayback = value; notifyListeners(); }

  void setPreset(String name) {
    equalizerPreset = name;
    switch (name) {
      case 'Pop': bands = [.45, .52, .56, .58, .54, .55, .52, .58, .56]; break;
      case 'Rock': bands = [.60, .56, .48, .42, .49, .52, .58, .64, .61]; break;
      case 'Eletrônica': bands = [.44, .55, .61, .56, .45, .48, .42, .51, .58]; break;
      default: bands = List.filled(9, .5); break;
    }
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    notifyListeners();
  }

  void clearQueue() {
    queue.clear();
    playing = false;

    notifyListeners();
  }

  @override
  void dispose() {
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
