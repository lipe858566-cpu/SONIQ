import 'package:flutter/material.dart';

import '../state/soniq_controller.dart';
import '../theme/soniq_theme.dart';

String formatDuration(Duration value) {
  final seconds = value.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}


class PlayerProgressBar extends StatefulWidget {
  const PlayerProgressBar({super.key, this.compact = false});

  final bool compact;

  @override
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final player = state.engine.player;
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? player.position;
        final total = state.actualDuration ?? state.activeTrack.length;
        final totalMs = total.inMilliseconds;
        final fraction = totalMs <= 0 ? 0.0 : (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        if (widget.compact) {
          return Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: fraction, minHeight: 2.5, color: state.accent),
            ),
          );
        }
        final shown = _dragValue ?? fraction;
        return Column(children: [
          Slider(
            value: shown,
            onChanged: totalMs <= 0 ? null : (value) => setState(() => _dragValue = value),
            onChangeEnd: (value) {
              setState(() => _dragValue = null);
              state.seekTo(Duration(milliseconds: (value * totalMs).round()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formatDuration(Duration(milliseconds: (shown * totalMs).round())),
                  style: const TextStyle(fontSize: 11, color: SoniqColors.muted)),
              Text(totalMs <= 0 ? '--:--' : formatDuration(total),
                  style: const TextStyle(fontSize: 11, color: SoniqColors.muted)),
            ]),
          ),
        ]);
      },
    );
  }
}
