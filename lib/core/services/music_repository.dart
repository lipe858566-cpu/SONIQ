import '../models/music_models.dart';

abstract interface class MusicRepository {
  Future<List<Track>> trending({int limit = 24});
  Future<List<Track>> search(String query);
  Future<List<Track>> byIds(List<String> ids);
}

class BackendConfiguration {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
