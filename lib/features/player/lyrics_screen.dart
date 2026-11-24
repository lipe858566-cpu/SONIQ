import 'package:flutter/material.dart';
import '../../core/models/music_models.dart';
import '../../core/state/soniq_controller.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key, required this.track});
  final Track track;

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}
class _LyricsScreenState extends State<LyricsScreen> {
  final scroll = ScrollController();
  int lastIndex = -2;
  @override
  void dispose() { scroll.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final track = widget.track;
    final lyrics = track.lyrics?.trim() ?? '';
    final entries = <MapEntry<int, String>>[];
    final pattern = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\]');
    for (final line in lyrics.split('\n')) {
      for (final match in pattern.allMatches(line)) {
        final time = int.parse(match.group(1)!) * 60000 + (double.parse(match.group(2)!) * 1000).round();
        entries.add(MapEntry(time, line.replaceAll(pattern, '').trim()));
      }
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return Scaffold(appBar: AppBar(title: Text(track.title)), body: lyrics.isEmpty
      ? const Center(child: Text('Letras ainda não disponíveis.'))
      : entries.isEmpty ? SingleChildScrollView(padding: const EdgeInsets.all(24), child: Text(lyrics))
      : StreamBuilder<Duration>(stream: state.engine.player.positionStream, builder: (context, snapshot) {
        final position = state.activeTrackId == track.id ? snapshot.data?.inMilliseconds ?? 0 : -1;
        final index = entries.lastIndexWhere((entry) => entry.key <= position);
        if (index != lastIndex) {
          lastIndex = index;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && scroll.hasClients) scroll.animateTo((index * 90.0 - 90).clamp(0.0, scroll.position.maxScrollExtent).toDouble(), duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          });
        }
        return ListView.builder(controller: scroll, itemExtent: 90, itemCount: entries.length, padding: const EdgeInsets.all(24), itemBuilder: (context, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(entries[i].value, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, color: i == index ? state.accent : Colors.white60, fontWeight: i == index ? FontWeight.bold : FontWeight.normal))));
      }));
  }
}
