import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/music_models.dart';
import 'music_repository.dart';

/// YouTube Data API: search metadata only. Videos play in the official embedded player.
class YouTubeRepository implements MusicRepository {
  YouTubeRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Future<List<Track>> trending({int limit = 24}) => search('música oficial Brasil hits');

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return [];
    dynamic payload;
    if (BackendConfiguration.apiBaseUrl.isNotEmpty) {
      final base = BackendConfiguration.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
      final response = await _client.get(Uri.parse('$base/search').replace(queryParameters: {'q': query})).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Erro na pesquisa (${response.statusCode}).');
      payload = jsonDecode(response.body);
    } else if (BackendConfiguration.hasSupabase && BackendConfiguration.youtubeApiKey.isEmpty) {
      // Requires an Edge Function named youtube-search deployed to the Supabase project.
      final response = await Supabase.instance.client.functions.invoke('youtube-search', queryParameters: {'q': query});
      if (response.status != 200) throw StateError('Pesquisa indisponível (${response.status}). Configure a função youtube-search.');
      payload = response.data;
    } else {
      if (BackendConfiguration.youtubeApiKey.isEmpty) {
        throw StateError('Configure YOUTUBE_API_KEY ou a função youtube-search do Supabase.');
      }
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet', 'q': query, 'type': 'video', 'videoEmbeddable': 'true',
        'maxResults': '20', 'key': BackendConfiguration.youtubeApiKey,
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('YouTube indisponível (${response.statusCode}). Verifique chave, restrições e cota.');
      payload = jsonDecode(response.body);
    }
    if (payload is String) payload = jsonDecode(payload);
    if (payload is! Map) throw StateError('Resposta inesperada da pesquisa.');
    final items = payload['items'] as List? ?? [];
    return items.whereType<Map>().map((item) {
      final snippet = item['snippet'] as Map? ?? {};
      final id = item['id'];
      final videoId = id is Map ? id['videoId']?.toString() : id?.toString();
      final thumbnails = snippet['thumbnails'] as Map? ?? {};
      final high = thumbnails['high'] as Map? ?? thumbnails['medium'] as Map? ?? {};
      return Track(
        id: videoId ?? '', title: _plain(snippet['title']?.toString() ?? 'Sem título'),
        artist: _plain(snippet['channelTitle']?.toString() ?? 'YouTube'),
        duration: '--:--', cover: 'assets/covers/focus.jpg', genre: 'Música',
        artworkUrl: high['url']?.toString(), playable: true,
      );
    }).where((track) => track.id.isNotEmpty).toList();
  }

  String _plain(String value) => value.replaceAll('&amp;', '&').replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>');

  @override
  Future<List<MusicPlaylist>> playlistsForUser(String userId) async => [];
  @override
  Future<Uri?> playableUriFor(String trackId) async => null;
}
