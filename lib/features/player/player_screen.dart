import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import 'equalizer_screen.dart';
import 'queue_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  YoutubePlayerController? _youtube;
  String? _videoId;

  void _ensureVideo(String id) {
    if (_videoId == id) return;
    _youtube?.close();
    _videoId = id;
    _youtube = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: false,
      params: const YoutubePlayerParams(showControls: true, showFullscreenButton: true),
    );
  }

  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() { _orbit.dispose(); _youtube?.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final track = state.activeTrack;
    if (track.playable) _ensureVideo(track.id);
    final width = MediaQuery.of(context).size.width;
    final artSize = math.min(width - 76, 338.0);
    return Stack(children: [
      ListView(padding: const EdgeInsets.fromLTRB(23, 16, 23, 105), children: [
        Row(children: [
          CircleGlassButton(icon: Icons.keyboard_arrow_down_rounded, onTap: () => state.setTab(0)),
          const Spacer(),
          IconButton(onPressed: () => showDemoMessage(context, 'Transmissão disponível com um serviço de áudio compatível.'), icon: const Icon(Icons.cast_rounded)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())), icon: const Icon(Icons.more_vert_rounded)),
        ]),
        const SizedBox(height: 10),
        if (track.playable && _youtube != null)
          Padding(padding: const EdgeInsets.only(bottom: 18), child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: YoutubePlayer(controller: _youtube!),
          )),
        if (!track.playable) Center(child: AnimatedBuilder(animation: _orbit, builder: (_, __) => SizedBox(
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
        ))),
        const SizedBox(height: 19),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(track.artist, style: const TextStyle(fontSize: 14, color: SoniqColors.muted)),
          ])),
          IconButton(
            onPressed: () => state.toggleFavorite(track.id),
            icon: Icon(state.favorites.contains(track.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: state.accent, size: 29),
          ),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          _Pill(icon: Icons.graphic_eq_rounded, label: track.playable ? 'Vídeo do YouTube' : 'Faixa ilustrativa', color: SoniqColors.cyan),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => showDemoMessage(context, 'Letras serão exibidas quando a API estiver conectada.'),
            child: const _Pill(icon: Icons.lyrics_outlined, label: 'Letra')),
          const Spacer(),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerScreen())),
            icon: const Icon(Icons.tune_rounded)),
        ]),
        const SizedBox(height: 16),
        AnimatedBuilder(animation: _orbit, builder: (_, __) => SizedBox(
          height: 45,
          child: CustomPaint(painter: _WaveformPainter(phase: _orbit.value * math.pi * 2, active: state.playing, accent: state.accent)),
        )),
        if (state.playbackError != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(state.playbackError!, style: const TextStyle(color: Color(0xFFFFB1C6), fontSize: 11)),
          ),
        ],
        if (!track.playable) Slider(value: state.progress.clamp(0.0, 1.0).toDouble(), onChanged: null),
        if (!track.playable) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_progressTime(state.progress, track.duration), style: const TextStyle(fontSize: 11)),
          Text(track.duration, style: const TextStyle(fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        if (!track.playable) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: state.toggleShuffle, icon: Icon(Icons.shuffle_rounded,
            color: state.shuffle ? state.accent : null, size: 24)),
          IconButton(onPressed: state.previousTrack, icon: const Icon(Icons.skip_previous_rounded, size: 32)),
          GestureDetector(
            onTap: state.togglePlay,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(colors: [state.accent, SoniqColors.violet]),
                border: Border.all(color: Colors.white.withOpacity(.8), width: 1.6),
                boxShadow: [BoxShadow(color: state.accent.withOpacity(.6), blurRadius: 27)]),
              child: state.isBuffering
                  ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 39, color: Colors.white),
            ),
          ),
          IconButton(onPressed: state.nextTrack, icon: const Icon(Icons.skip_next_rounded, size: 32)),
          IconButton(onPressed: state.toggleRepeat, icon: Icon(Icons.repeat_rounded,
            color: state.repeat ? state.accent : null, size: 24)),
        ]),
      ]),
      Positioned(left: 18, right: 18, bottom: MediaQuery.of(context).padding.bottom + 12,
        child: GlassPanel(
          glow: true,
          radius: 23,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())),
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

  String _progressTime(double value, String duration) {
    final parts = duration.split(':');
    if (parts.length != 2) return '0:00';
    final seconds = ((int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0)) * value;
    final time = seconds.round();
    return '${time ~/ 60}:${(time % 60).toString().padLeft(2, '0')}';
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

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.phase, required this.active, required this.accent});
  final double phase;
  final bool active;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 62;
    final step = size.width / count;
    for (var i = 0; i < count; i++) {
      final t = i / count;
      final amplitude = (math.sin(i * .63) * math.cos(i * .17) + 1.3) / 2.3;
      final movement = active ? math.sin(phase * 2 + i * .31) * .20 : 0;
      final h = 6 + (amplitude + movement) * (size.height - 11);
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4
        ..color = Color.lerp(accent, t > .55 ? Colors.white : SoniqColors.cyan, t > .55 ? (t - .55) * 2 : t * .7)!;
      canvas.drawLine(Offset(i * step + 2, (size.height - h) / 2), Offset(i * step + 2, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => phase != old.phase || active != old.active || accent != old.accent;
}
