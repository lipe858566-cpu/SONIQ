import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../../core/widgets/track_tile.dart';
import '../playlists/playlists_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 35), children: [
      Row(children: [
        Expanded(child: Text('Minha Biblioteca', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
        CircleGlassButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
      ]),
      const SizedBox(height: 22),
      _LibraryRow(icon: Icons.music_note_outlined, title: 'Músicas', subtitle: '${state.tracks.where((t) => t.playable).length} músicas encontradas', onTap: () => _open(context, const LibraryTracksScreen(title: 'Músicas'))),
      _LibraryRow(icon: Icons.playlist_add_rounded, title: 'Playlists', subtitle: '${state.playlists.length} playlists', onTap: () => _open(context, const LibraryPlaylistsScreen())),
      _LibraryRow(icon: Icons.download_rounded, title: 'Download', subtitle: 'Indisponível nesta BETA', onTap: () => showDemoMessage(context, 'Os downloads reais dependem de uma API de áudio autorizada.')),
      _LibraryRow(icon: Icons.person_outline_rounded, title: 'Artistas', subtitle: 'Disponíveis na busca', onTap: () => showDemoMessage(context, 'Artistas serão carregados pela API musical.')),
      _LibraryRow(icon: Icons.album_outlined, title: 'Álbuns', subtitle: 'Em desenvolvimento', onTap: () => showDemoMessage(context, 'Álbuns serão carregados pela API musical.')),
      _LibraryRow(icon: Icons.sensors_rounded, title: 'Rádios', subtitle: 'Em desenvolvimento', onTap: () => showDemoMessage(context, 'Rádios estarão disponíveis após conectar um serviço de áudio.')),
    ]));
  }

  void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        Icon(icon, color: SoniqScope.of(context).accent, size: 28),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: SoniqColors.muted)),
        ])),
        const Icon(Icons.chevron_right_rounded),
      ]),
    ),
  );
}

class LibraryTracksScreen extends StatelessWidget {
  const LibraryTracksScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final tracks = SoniqScope.of(context).tracks;
    return NeonScaffold(child: Column(children: [
      PageTitle(title),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 18), children: [
        const Text('Faixas encontradas e exemplos visuais', style: TextStyle(color: SoniqColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        for (final track in tracks) TrackTile(track: track),
      ])),
    ]));
  }
}

class LibraryPlaylistsScreen extends StatelessWidget {
  const LibraryPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) => NeonScaffold(child: Column(children: [
    const PageTitle('Playlists'),
    Expanded(child: PlaylistsScreen()),
  ]));
}
