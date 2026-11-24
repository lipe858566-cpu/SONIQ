import 'package:flutter/material.dart';

import '../../core/models/music_models.dart';
import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  bool _public = false;

  Future<void> _createPlaylist() async {
    final input = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Nova playlist'),
      content: TextField(controller: input, autofocus: true, maxLength: 40,
        decoration: const InputDecoration(hintText: 'Nome da playlist')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, input.text.trim()), child: const Text('Criar')),
      ],
    ));
    input.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    try {
      await SoniqScope.of(context).addPlaylist(name);
      if (mounted) showDemoMessage(context, 'Playlist criada.');
    } catch (error) { if (mounted) showDemoMessage(context, 'Não foi possível criar: $error'); }
  }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final playlists = _public ? <MusicPlaylist>[] : state.playlists;
    return ListView(padding: const EdgeInsets.fromLTRB(19, 24, 19, 116), children: [
      Row(children: [
        const Expanded(child: Text('Playlists', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
        IconButton(onPressed: () => state.setTab(1), icon: const Icon(Icons.search_rounded)),
        IconButton(onPressed: _createPlaylist, tooltip: 'Criar playlist', icon: const Icon(Icons.more_vert_rounded)),
      ]),
      const SizedBox(height: 11),
      GlassPanel(padding: const EdgeInsets.all(4), radius: 25, child: Row(children: [
        _Segment(label: 'Minhas', active: !_public, onTap: () => setState(() => _public = false)),
        _Segment(label: 'Públicas', active: _public, onTap: () => setState(() => _public = true)),
      ])),
      const SizedBox(height: 15),
      GlassPanel(
        padding: EdgeInsets.zero,
        radius: 12,
        onTap: _createPlaylist,
        child: const SizedBox(height: 43, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_rounded, size: 21), SizedBox(width: 8),
          Text('Nova Playlist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ])),
      ),
      const SizedBox(height: 12),
      for (final playlist in playlists) _PlaylistRow(playlist: playlist),
      if (_public) const Padding(padding: EdgeInsets.all(12), child: Text(
        'Ainda não há playlists públicas disponíveis. A publicação será habilitada quando o serviço estiver conectado.',
        style: TextStyle(fontSize: 11, color: SoniqColors.muted),
      )),
    ]);
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 33,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: active ? LinearGradient(colors: [SoniqScope.of(context).accent, SoniqColors.violet]) : null,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    ),
  ));
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlist});
  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassPanel(
        opacity: .30, borderOpacity: .08,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist))),
        child: Row(children: [
          if (playlist.id == 'favorites')
            Container(width: 49, height: 49, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [state.accent, const Color(0xFF35044F)]),
              borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.favorite_border_rounded, color: Colors.white))
          else CoverArt(playlist.cover, size: 49, radius: 10),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(playlist.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 4),
            Text('${playlist.count} músicas', style: const TextStyle(color: SoniqColors.muted, fontSize: 11)),
          ])),
          PopupMenuButton<String>(
            tooltip: 'Opções da playlist',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) async {
              if (value == 'open') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)));
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: const Text('Excluir playlist?'), content: Text(playlist.title), actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Excluir'))]));
                if (confirmed == true) {
                  try { await state.deletePlaylist(playlist.id); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível excluir: $error'))); }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('Abrir playlist')),
              if (state.isPersonalPlaylist(playlist.id))
                const PopupMenuItem(value: 'delete', child: Text('Excluir playlist')),
            ],
          ),
        ]),
      ),
    );
  }
}
