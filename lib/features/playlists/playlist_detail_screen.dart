import 'package:flutter/material.dart';

import '../../core/models/music_models.dart';
import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../../core/widgets/soniq_bottom_nav.dart';
import '../../core/widgets/track_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});
  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final tracks = playlist.id == 'favorites'
        ? state.favoriteTracks
        : playlist.trackIds.map((id) => state.tracks.where((track) => track.id == id).firstOrNull).whereType<Track>().toList();
    final hero = playlist.cover;
    return NeonScaffold(
      bottomNavigationBar: const SoniqBottomNav(),
      child: ListView(padding: const EdgeInsets.only(bottom: 115), children: [
        Stack(children: [
          SizedBox(height: 244, width: double.infinity, child: Image.asset(hero, fit: BoxFit.cover)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(.22), Colors.transparent, const Color(0xFF080611)],
          )))),
          Positioned(top: 14, left: 18, child: CircleGlassButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context))),
        ]),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 19), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CoverArt(playlist.cover, size: 74, radius: 13),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(playlist.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text('${playlist.count} músicas · Playlist SONIQ', style: const TextStyle(fontSize: 12, color: SoniqColors.muted)),
            ])),
          ]),
          const SizedBox(height: 19),
          Row(children: [
            Expanded(child: NeonButton(label: 'Reproduzir', icon: Icons.play_arrow_rounded, onPressed: () {
              if (!tracks.any((track) => track.playable)) { showDemoMessage(context, 'Esta playlist não tem músicas reproduzíveis.'); return; }
              state.playAll(tracks);
              state.setTab(2);
              Navigator.popUntil(context, (route) => route.isFirst);
            })),
            const SizedBox(width: 12),
            CircleGlassButton(icon: Icons.shuffle_rounded, size: 45, onTap: state.toggleShuffle, active: state.shuffle),
          ]),
          const SizedBox(height: 22),
          for (final track in tracks)
            Row(children: [
              Expanded(child: TrackTile(track: track)),
              if (state.isPersonalPlaylist(playlist.id))
                IconButton(
                  tooltip: 'Remover da playlist',
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                  onPressed: () async { try { await state.removeTrackFromPlaylist(playlist.id, track.id); } catch (error) { if (context.mounted) showDemoMessage(context, 'Não foi possível remover: $error'); } },
                ),
            ]),
          if (tracks.isEmpty) const Padding(padding: EdgeInsets.all(15), child: Text('Esta playlist ainda não tem músicas.', style: TextStyle(color: SoniqColors.muted))),
        ])),
      ]),
    );
  }
}
