import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/music_models.dart';
import 'music_repository.dart';



class CatalogRepository implements MusicRepository {
  static const _signedUrlSeconds = 6 * 60 * 60;
  static const _columns =
      'id,title,artist,album,genre,duration_seconds,audio_path,cover_path,lrc_path,lrc_text';

  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Track>> trending({int limit = 24}) => _fetch(limit: limit);

  @override
  Future<List<Track>> search(String query) {
    final term = query.replaceAll(RegExp(r'[%,()*\\]'), ' ').trim();
    if (term.isEmpty) return Future.value(const []);
    return _fetch(term: term, limit: 50);
  }

  @override
  Future<List<Track>> byIds(List<String> ids) async {
    final valid = ids.where(_isUuid).toList();
    if (valid.isEmpty) return const [];
    final rows = await _db.from('tracks').select(_columns).eq('published', true).inFilter('id', valid);
    return _toTracks(rows);
  }

  Future<List<Track>> _fetch({String? term, int limit = 50}) async {
    var query = _db.from('tracks').select(_columns).eq('published', true);
    if (term != null) {
      query = query.or('title.ilike.%$term%,artist.ilike.%$term%,album.ilike.%$term%,genre.ilike.%$term%');
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return _toTracks(rows);
  }

  Future<List<Track>> _toTracks(List<dynamic> rows) async {
    final items = rows.whereType<Map<String, dynamic>>().where((r) => (r['audio_path'] as String?)?.isNotEmpty ?? false).toList();
    if (items.isEmpty) return const [];
    final paths = items.map((r) => r['audio_path'] as String).toList();
    final signed = await _db.storage.from('music').createSignedUrls(paths, _signedUrlSeconds);
    final covers = _db.storage.from('covers');
    final tracks = <Track>[];
    for (var i = 0; i < items.length && i < signed.length; i++) {
      final row = items[i];
      String? lyrics = row['lrc_text'] as String?;
      final lrcPath = row['lrc_path'] as String?;
      if ((lyrics == null || lyrics.isEmpty) && lrcPath != null && lrcPath.isNotEmpty) {
        try { lyrics = utf8.decode(await _db.storage.from('lyrics').download(lrcPath)); } catch (_) {}
      }
      final coverPath = row['cover_path'] as String?;
      tracks.add(Track(
        id: row['id'] as String,
        title: row['title'] as String? ?? 'Sem título',
        artist: row['artist'] as String? ?? 'Artista desconhecido',
        album: row['album'] as String? ?? '',
        genre: row['genre'] as String? ?? 'Música',
        duration: Track.formatSeconds((row['duration_seconds'] as num?)?.toInt() ?? 0),
        cover: 'assets/covers/focus.jpg',
        artworkUrl: coverPath == null || coverPath.isEmpty ? null : covers.getPublicUrl(coverPath),
        audioUrl: signed[i].signedUrl,
        lrcPath: row['lrc_path'] as String?,
        lyrics: lyrics,
      ));
    }
    return tracks;
  }

  static final _uuid = RegExp(r'^[0-9a-fA-F-]{36}$');
  static bool _isUuid(String value) => _uuid.hasMatch(value);
}
