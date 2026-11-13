import '../models/music_models.dart';

/// Source of public tracks that can be streamed by the application.
abstract interface class MusicRepository {
  Future<List<Track>> trending({int limit = 24});
  Future<List<Track>> search(String query);
  Future<List<MusicPlaylist>> playlistsForUser(String userId);
  Future<Uri?> playableUriFor(String trackId);
}

abstract interface class AccountRepository {
  Future<void> updateProfile({
    required String displayName,
    required String username,
    required String bio,
  });

  Future<void> savePlaylist(MusicPlaylist playlist);
}

class BackendConfiguration {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('MUSIC_API_BASE_URL');
  static const youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
