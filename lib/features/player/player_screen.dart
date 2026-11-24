import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../../core/widgets/player_progress.dart';
import 'equalizer_screen.dart';
import 'queue_screen.dart';
import 'lyrics_screen.dart';
import 'comments_screen.dart';
import 'download_button.dart';
import 'package:flutter/services.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  void _syncAnimation(bool visible, bool playing) {
    final shouldRun = visible && playing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldRun && !_orbit.isAnimating) {
        _orbit.repeat();
      } else if (!shouldRun && _orbit.isAnimating) {
        _orbit.stop();
      }
    });
  }

  void _openQueue() => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final track = state.activeTrack;
    _syncAnimation(state.selectedTab == 2, state.playing && !state.isBuffering);
    if (track.id.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Nenhuma música selecionada'), TextButton(onPressed: () => state.setTab(1), child: const Text('Explorar catálogo'))]));
    final width = MediaQuery.of(context).size.width;
    final artSize = math.min(width - 76, 338.0);
    final buffering = state.isBuffering;
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(23, 16, 23, 105), children: [
        Row(children: [
          CircleGlassButton(icon: Icons.keyboard_arrow_down_rounded, onTap: () => state.setTab(0)),
          const Spacer(),
          IconButton(
            tooltip: 'Fila de reprodução',
            onPressed: _openQueue,
            icon: const Icon(Icons.queue_music_rounded),
          ),
        ]),
        const SizedBox(height: 10),
        Center(child: RepaintBoundary(child: AnimatedBuilder(animation: _orbit, builder: (_, __) => SizedBox(
          width: artSize + 18, height: artSize + 18,
          child: CustomPaint(
            painter: _OrbitPainter(phase: _orbit.value * math.pi * 2, accent: state.accent, playing: state.playing),
            child: Center(child: Container(
              width: artSize - 16, height: artSize - 16,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.15), width: 2),
                boxShadow: [BoxShadow(color: state.accent.withOpacity(.28), blurRadius: 34, spreadRadius: 3)]),
              child: ClipOval(child: CoverArt(track.image, size: artSize - 16, radius: artSize)),
            )),
          ),
        )))),
        const SizedBox(height: 19),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: SoniqColors.muted)),
          ])),
          IconButton(
            tooltip: state.favorites.contains(track.id) ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            onPressed: () => state.toggleFavorite(track.id),
            icon: Icon(state.favorites.contains(track.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: state.accent, size: 29),
          ),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          _Pill(icon: Icons.graphic_eq_rounded, label: track.playable ? 'Catálogo SONIQ' : 'Áudio indisponível', color: SoniqColors.cyan),
          const Spacer(),
          IconButton(
            tooltip: 'Equalizador',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerScreen())),
            icon: const Icon(Icons.tune_rounded),
          ),
        ]),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(track: track))), icon: const Icon(Icons.lyrics_outlined), label: const Text('Letras')),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(trackId: track.id))), icon: const Icon(Icons.chat_bubble_outline), label: const Text('Comentários')),
          TextButton.icon(onPressed: () async {
            const base = String.fromEnvironment('SONIQ_SHARE_URL');
            if (base.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link público ainda não configurado.'))); return; }
            try { await const MethodChannel('soniq/native').invokeMethod('share', '${track.title} - ${track.artist}\n${Uri.parse(base).replace(queryParameters: {'track': track.id})}'); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível compartilhar.'))); }
          }, icon: const Icon(Icons.share_outlined), label: const Text('Compartilhar')),
        ]),
        DownloadButton(key: ValueKey(track.id), track: track),
        const Text('Visualizador de áudio em desenvolvimento', style: TextStyle(fontSize: 11, color: SoniqColors.muted)),
        if (state.playbackError != null) Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(children: [
            Expanded(child: Text(state.playbackError!, style: const TextStyle(color: Color(0xFFFFB1C6), fontSize: 11))),
            if (track.playable) TextButton(onPressed: state.retryPlayback, child: const Text('Tentar novamente')),
          ]),
        ),
        if (track.playable) const PlayerProgressBar() else const SizedBox(height: 40),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            tooltip: 'Aleatório',
            onPressed: state.toggleShuffle,
            icon: Icon(Icons.shuffle_rounded, color: state.shuffle ? state.accent : null, size: 24),
          ),
          IconButton(tooltip: 'Anterior', onPressed: state.previousTrack, icon: const Icon(Icons.skip_previous_rounded, size: 32)),
          GestureDetector(
            onTap: buffering || !track.playable ? null : state.togglePlay,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [state.accent, SoniqColors.violet]),
                border: Border.all(color: Colors.white.withOpacity(.8), width: 1.6),
                boxShadow: [BoxShadow(color: state.accent.withOpacity(.6), blurRadius: 27)],
              ),
              child: buffering
                  ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 39, color: Colors.white),
            ),
          ),
          IconButton(tooltip: 'Próxima', onPressed: state.nextTrack, icon: const Icon(Icons.skip_next_rounded, size: 32)),
          IconButton(
            tooltip: switch (state.repeatMode) { 1 => 'Repetir fila', 2 => 'Repetir faixa', _ => 'Repetição desativada' },
            onPressed: state.toggleRepeat,
            icon: Icon(state.repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: state.repeat ? state.accent : null, size: 24),
          ),
        ]),
      ]),
      Positioned(left: 18, right: 18, bottom: MediaQuery.of(context).padding.bottom + 12,
        child: GlassPanel(
          glow: true,
          radius: 23,
          onTap: _openQueue,
          child: const Row(children: [
            Icon(Icons.playlist_play_rounded, size: 25),
            Spacer(),
            Text('Fila de reprodução', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Spacer(),
            Icon(Icons.keyboard_arrow_up_rounded),
          ]),
        ),
      ),
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => GlassPanel(
    radius: 30, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color), const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.phase, required this.accent, required this.playing});
  final double phase;
  final Color accent;
  final bool playing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final trackPaint = Paint()..color = accent.withOpacity(.18)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(center, radius, trackPaint);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: [SoniqColors.cyan, accent, Colors.white, accent],
        transform: GradientRotation(phase)).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 1.7 + phase * (playing ? 1 : .2), math.pi * 1.08, false, arc);
    final point = Offset(center.dx + radius * math.cos(phase - math.pi / 1.7), center.dy + radius * math.sin(phase - math.pi / 1.7));
    canvas.drawCircle(point, 4.3, Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawCircle(point, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => phase != old.phase || accent != old.accent || playing != old.playing;
}

