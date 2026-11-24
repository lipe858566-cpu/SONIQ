import 'package:flutter/material.dart';

import '../models/music_models.dart';
import '../state/soniq_controller.dart';
import '../theme/soniq_theme.dart';
import 'neon_scaffold.dart';

Future<void> _choosePlaylist(BuildContext context, SoniqController state, Track track) async {
  final playlists = state.playlists.where((item) => state.isPersonalPlaylist(item.id)).toList();
  if (playlists.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crie uma playlist na aba Favoritos primeiro.')),
    );
    return;
  }
  final id = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(child: ListView(
      shrinkWrap: true,
      children: [
        const ListTile(title: Text('Adicionar à playlist')),
        for (final playlist in playlists)
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(playlist.title),
            trailing: playlist.trackIds.contains(track.id)
                ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.pop(sheetContext, playlist.id),
          ),
      ],
    )),
  );
  if (id == null || !context.mounted) return;
  try { await state.addTrackToPlaylist(id, track.id); } catch (error) { if (context.mounted) showDemoMessage(context, 'Não foi possível adicionar: $error'); return; }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Música adicionada à playlist.')),
  );
}

class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track, this.onTap, this.leadingIcon = false, this.showMore = true});

  final Track track;
  final VoidCallback? onTap;
  final bool leadingIcon;
  final bool showMore;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final active = state.activeTrackId == track.id;
    final liked = state.favorites.contains(track.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassPanel(
        opacity: active ? .70 : .25,
        borderOpacity: active ? .38 : .08,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        onTap: onTap ?? () { state.selectTrack(track); state.setTab(2); Navigator.of(context).popUntil((route) => route.isFirst); },
        child: Row(children: [
          if (leadingIcon) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.drag_indicator, size: 18, color: Colors.white54)),
          CoverArt(track.image, size: 45, radius: 9),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${track.artist} · ${track.duration}${track.playable ? '' : ' · Exemplo'}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? SoniqColors.muted : Colors.black54)),
          ])),
          if (active) const Icon(Icons.graphic_eq, color: SoniqColors.cyan, size: 19),
          IconButton(
            tooltip: liked ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            visualDensity: VisualDensity.compact,
            icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20,
              color: liked ? state.accent : null),
            onPressed: () => state.toggleFavorite(track.id),
          ),
          if (showMore) PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              if (action == 'play') {
                state.selectTrack(track);
                state.setTab(2);
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else if (action == 'queue') {
                state.enqueue(track);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(track.playable ? 'Adicionada à fila.' : 'Esta faixa é ilustrativa.')),
                );
              } else if (action == 'playlist') {
                _choosePlaylist(context, state, track);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'play', child: Text('Reproduzir')),
              PopupMenuItem(value: 'queue', child: Text('Adicionar à fila')),
              PopupMenuItem(value: 'playlist', child: Text('Adicionar à playlist')),
            ],
          ),
        ]),
      ),
    );
  }
}
