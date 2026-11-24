import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/catalog_collections.dart';
import '../../core/models/music_models.dart';
import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../../core/widgets/track_tile.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _filter = 'Tudo';
  bool _loading = false;
  String? _error;
  List<Track> _results = [];
  int _searchVersion = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    if (text.trim().isEmpty) {
      setState(() { _results = []; _error = null; _loading = false; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final tracks = await SoniqScope.of(context).searchTracks(text);
        if (!mounted || version != _searchVersion) return;
        setState(() { _results = tracks; _loading = false; });
      } catch (error) {
        if (!mounted || version != _searchVersion) return;
        setState(() { _error = 'Não foi possível pesquisar agora. Verifique a conexão.'; _loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final query = _search.text.trim();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 25, 20, 115), children: [
      const Text('Explorar', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      TextField(
        controller: _search,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Buscar músicas, artistas ou álbuns...',
          hintStyle: const TextStyle(fontSize: 12, color: SoniqColors.muted),
          suffixIcon: query.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {
                  _search.clear();
                  _onSearchChanged('');
                })
              : const Icon(Icons.tune_rounded, size: 20),
        ),
      ),
      const SizedBox(height: 14),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (final filter in ['Tudo', 'Músicas', 'Artistas', 'Álbuns'])
          Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(
            label: Text(filter, style: const TextStyle(fontSize: 11)),
            selected: _filter == filter,
            selectedColor: state.accent,
            labelStyle: TextStyle(color: _filter == filter ? Colors.white : null),
            onSelected: (_) => setState(() => _filter = filter),
            side: BorderSide(color: state.accent.withOpacity(.24)),
            visualDensity: VisualDensity.compact,
          )),
      ])),
      const SizedBox(height: 21),
      if (query.isNotEmpty) ...[
        SectionTitle('Resultados encontrados (${_results.length})'),
        if (_loading) const Padding(
          padding: EdgeInsets.all(22),
          child: Center(child: CircularProgressIndicator()),
        ),
        if (_error != null) Padding(
          padding: const EdgeInsets.all(14),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFFFB1C6), fontSize: 12)),
        ),
        if (!_loading && _error == null) ...[
          if (_filter == 'Álbuns')
            const GlassPanel(child: Text('A busca de álbuns chega em uma próxima atualização. Busque músicas ou artistas por enquanto.'))
          else if (_filter == 'Artistas')
            for (final artist in _results.map((track) => track.artist).toSet())
              Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassPanel(
                child: Row(children: [
                  const Icon(Icons.person_rounded, color: SoniqColors.cyan),
                  const SizedBox(width: 12),
                  Expanded(child: Text(artist)),
                ]),
              ))
          else
            for (final track in _results) TrackTile(track: track),
          if (_results.isEmpty && _filter != 'Álbuns')
            const Padding(padding: EdgeInsets.all(18), child: Text('Nenhuma música encontrada.')),
        ],
      ] else ...[
        const SectionTitle('Gêneros', action: 'Descubra ›'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: CatalogCollections.genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .98,
          ),
          itemBuilder: (context, index) => _GenreCard(genre: CatalogCollections.genres[index]),
        ),
        const SizedBox(height: 26),
        SectionTitle('Em alta no momento', action: 'Atualizar ↻', onAction: state.initializeCatalog),
        if (state.catalogLoading)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (state.catalogError != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(state.catalogError!, style: const TextStyle(fontSize: 12)))
        else
          for (final track in state.tracks.where((track) => track.playable).take(10)) TrackTile(track: track),
        const SizedBox(height: 18),
        const Text('As melhores músicas são no SONIQ',
            style: TextStyle(fontSize: 11, color: SoniqColors.muted)),
      ],
    ]);
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.genre});
  final MusicGenre genre;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GenreTracksScreen(genre: genre.name))),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SoniqColors.purple.withOpacity(.4)),
        image: DecorationImage(image: AssetImage(genre.cover), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(.85)],
        )),
        child: Text(genre.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    ),
  );
}

class GenreTracksScreen extends StatefulWidget {
  const GenreTracksScreen({super.key, required this.genre});
  final String genre;

  @override
  State<GenreTracksScreen> createState() => _GenreTracksScreenState();
}

class _GenreTracksScreenState extends State<GenreTracksScreen> {
  Future<List<Track>>? _tracks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracks ??= SoniqScope.of(context).searchTracks(widget.genre);
  }

  @override
  Widget build(BuildContext context) => NeonScaffold(child: Column(children: [
    PageTitle(widget.genre),
    Expanded(child: FutureBuilder<List<Track>>(
      future: _tracks,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(snapshot.error.toString())));
        }
        final tracks = snapshot.data ?? [];
        return ListView(padding: const EdgeInsets.symmetric(horizontal: 18), children: [
          Text('Músicas relacionadas a ${widget.genre}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 15),
          if (tracks.isEmpty) const GlassPanel(child: Text('Nenhuma música encontrada.')),
          for (final track in tracks) TrackTile(track: track),
        ]);
      },
    )),
  ]));
}
