import 'package:flutter/material.dart';
import 'dart:async';
import '../core/state/soniq_controller.dart';
import '../core/models/music_models.dart';
import '../services/ytdlp_service.dart';

class YtdlpMusicScreen extends StatefulWidget {
  const YtdlpMusicScreen({super.key});

  @override
  State<YtdlpMusicScreen> createState() => _YtdlpMusicScreenState();
}

class _YtdlpMusicScreenState extends State<YtdlpMusicScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Track> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await YtdlpService.searchMusic(query);
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  Future<void> _playTrack(Track track) async {
    final controller = SoniqScope.of(context);
    
    setState(() {
      _error = null;
    });

    try {
      // 🔗 SÓ AGORA — busca a URL do áudio quando o usuário CLICAR
      final audioUrl = await YtdlpService.getAudioUrl(
        "https://www.youtube.com/watch?v=${track.id}"
      );

      // 🎵 Cria um Track completo com a URL do áudio
      final playableTrack = Track(
        id: track.id,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
        cover: track.cover,
        genre: track.genre,
        album: track.album,
        artworkUrl: track.artworkUrl,
        audioUrl: audioUrl,
      );

      // ▶️ Toca usando o controlador
      if (mounted) {
        controller.selectTrack(playableTrack);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎵 Carregando...'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Músicas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 Barra de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar música...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: _onSearchChanged,
            ),
            
            const SizedBox(height: 12),

            // ❌ Mensagem de erro
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // ⏳ Carregando
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))

            // 📋 Resultados
            else if (_results.isEmpty)
              const Expanded(child: Center(child: Text('Busque uma música acima!')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final track = _results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  track.artworkUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 50),
                                ),
                              )
                            : const Icon(Icons.music_note, size: 50),
                        title: Text(track.title),
                        subtitle: Text(track.artist),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: () => _playTrack(track),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
