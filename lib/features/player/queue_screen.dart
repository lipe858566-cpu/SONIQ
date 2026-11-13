import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final tracks = state.queueTracks;
    return NeonScaffold(child: Column(children: [
      PageTitle('Fila de reprodução (${tracks.length})', actions: [
        IconButton(onPressed: state.clearQueue, icon: const Icon(Icons.delete_outline_rounded, size: 22)),
      ]),
      const SizedBox(height: 8),
      Expanded(child: tracks.isEmpty
        ? const Center(child: Text('Sua fila está vazia.', style: TextStyle(color: SoniqColors.muted)))
        : ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          buildDefaultDragHandles: false,
          itemCount: tracks.length,
          onReorder: state.reorderQueue,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return Padding(
              key: ValueKey(track.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                opacity: state.activeTrackId == track.id ? .8 : .33,
                child: Row(children: [
                  ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_indicator_rounded, size: 21, color: SoniqColors.muted)),
                  const SizedBox(width: 8),
                  CoverArt(track.image, size: 48, radius: 9),
                  const SizedBox(width: 11),
                  Expanded(child: GestureDetector(
                    onTap: () { state.selectTrack(track); Navigator.pop(context); },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(track.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('${track.artist} · ${track.duration}', style: const TextStyle(fontSize: 10, color: SoniqColors.muted)),
                    ]),
                  )),
                  if (state.activeTrackId == track.id) Icon(Icons.graphic_eq_rounded, color: state.accent),
                  IconButton(icon: const Icon(Icons.more_vert_rounded, size: 19), onPressed: () => showDemoMessage(context, 'Reordene segurando o ícone à esquerda.')),
                ]),
              ),
            );
          },
        )),
      Padding(padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).padding.bottom + 18), child: Row(children: [
        Expanded(child: GlassPanel(
          padding: const EdgeInsets.symmetric(vertical: 13),
          onTap: state.clearQueue,
          child: const Center(child: Text('Limpar fila', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        )),
        const SizedBox(width: 10),
        Expanded(child: NeonButton(label: 'Salvar como playlist', compact: true, onPressed: () {
          if (state.queue.isEmpty) { showDemoMessage(context, 'Adicione músicas à fila primeiro.'); return; }
          state.addPlaylist('Minha fila', trackIds: List.of(state.queue));
          showDemoMessage(context, 'Playlist "Minha fila" criada!');
        })),
      ])),
    ]));
  }
}
