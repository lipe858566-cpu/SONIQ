import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/music_models.dart';

class YtdlpService {
  static const String _baseUrl = "https://reentry-tacky-energize.ngrok-free.dev";


  static Future<List<Track>> searchMusic(String query) async {
    final url = Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        
        return results.map((json) => Track(
          id: json['id'] ?? '',
          title: json['title'] ?? 'Sem título',
          artist: json['artist'] ?? 'Desconhecido',
          duration: Track.formatSeconds(json['duration'] ?? 0),
          cover: json['thumbnail'] ?? '',
          genre: 'YouTube',
          album: '',
          artworkUrl: json['thumbnail'],
        )).toList();
      }
      
      throw Exception('Erro: ${response.statusCode}');
    } catch (e) {
      throw Exception('Sem conexão com o servidor Python! Inicie ele com "python app.py". Detalhe: $e');
    }
  }

  static Future<String> getAudioUrl(String videoUrl) async {
    final url = Uri.parse('$_baseUrl/stream?url=${Uri.encodeComponent(videoUrl)}');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['audio_url'];
      }
      
      throw Exception('Erro ao obter áudio: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }
}
