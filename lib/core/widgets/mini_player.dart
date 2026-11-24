import 'package:flutter/material.dart';

import '../state/soniq_controller.dart';
import '../theme/soniq_theme.dart';
import 'neon_scaffold.dart';
import 'player_progress.dart';


class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    if (!state.hasActivePlayback) return const SizedBox.shrink();
    final track = state.activeTrack;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: GlassPanel(
        glow: true,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
        onTap: () => state.setTab(2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            CoverArt(track.image, size: 42, radius: 9),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: SoniqColors.muted)),
            ])),
            IconButton(
              tooltip: 'Anterior',
              visualDensity: VisualDensity.compact,
              onPressed: state.previousTrack,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton(
              tooltip: state.playing ? 'Pausar' : 'Reproduzir',
              visualDensity: VisualDensity.compact,
              onPressed: state.isBuffering ? null : state.togglePlay,
              icon: state.isBuffering
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
            ),
            IconButton(
              tooltip: 'Próxima',
              visualDensity: VisualDensity.compact,
              onPressed: state.nextTrack,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ]),
          const PlayerProgressBar(compact: true),
        ]),
      ),
    );
  }
}
