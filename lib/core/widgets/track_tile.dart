import 'package:flutter/material.dart';

import '../models/music_models.dart';
import '../state/soniq_controller.dart';
import '../theme/soniq_theme.dart';
import 'neon_scaffold.dart';

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
          if (showMore) IconButton(
            tooltip: 'Mais opções',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.more_vert, size: 18),
            onPressed: () => showDemoMessage(context, 'Use o coração para salvar nos favoritos. Mais opções chegam em breve.'),
          ),
        ]),
      ),
    );
  }
}
