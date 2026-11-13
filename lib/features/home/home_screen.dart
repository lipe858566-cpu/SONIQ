import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../library/library_screen.dart';
import '../playlists/playlist_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final first = state.tracks.firstWhere((track) => track.playable, orElse: () => state.tracks[1]);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 116), children: [
      Row(children: [
        const SoniqWaveMark(size: 34),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('SONIQ', style: TextStyle(color: SoniqColors.cyan, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
          Text('Música sem limites', style: TextStyle(fontSize: 9, color: SoniqColors.muted)),
        ]),
        const Spacer(),
        CircleGlassButton(icon: Icons.notifications_none_rounded, onTap: () => showDemoMessage(context, 'Nenhuma notificação no momento.')),
        const SizedBox(width: 10),
        GestureDetector(onTap: () => state.setTab(4), child: const CoverArt('assets/avatars/profile.jpg', size: 38, radius: 22)),
      ]),
      const SizedBox(height: 24),
      Text('Olá, ${state.displayName.split(' ').first} 👋', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      const Text('Pronto para ouvir algo novo?', style: TextStyle(color: SoniqColors.muted, fontSize: 13)),
      const SizedBox(height: 10),
      if (state.catalogLoading)
        const Padding(padding: EdgeInsets.only(bottom: 10), child: Row(children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Carregando músicas...', style: TextStyle(fontSize: 11)),
        ]))
      else if (state.catalogError != null)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassPanel(
          child: Text(state.catalogError!, style: const TextStyle(fontSize: 11, color: SoniqColors.muted)),
        ))
      else
        const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('🎧 As melhores músicas estão no SONIQ', style: TextStyle(fontSize: 11, color: SoniqColors.cyan))),
      const SizedBox(height: 17),
      _DiscoveryBanner(onTap: () => state.setTab(1)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 4; i++) Container(
          width: i == 0 ? 8 : 6, height: i == 0 ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: i == 0 ? Colors.white : state.accent.withOpacity(.40)),
        ),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        _Shortcut(icon: Icons.graphic_eq_rounded, label: 'Mixes', color: SoniqColors.cyan, onTap: () => state.setTab(1)),
        const SizedBox(width: 9),
        _Shortcut(icon: Icons.sensors_rounded, label: 'Rádios', color: state.accent, onTap: () => state.setTab(1)),
        const SizedBox(width: 9),
        _Shortcut(icon: Icons.explore_outlined, label: 'Explorar', color: SoniqColors.cyan, onTap: () => state.setTab(1)),
        const SizedBox(width: 9),
        _Shortcut(icon: Icons.grid_view_rounded, label: 'Mais', color: state.accent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen()))),
      ]),
      const SizedBox(height: 23),
      SectionTitle('Continue ouvindo', action: 'Ver tudo ›', onAction: () => state.setTab(2)),
      GlassPanel(
        padding: const EdgeInsets.all(9),
        onTap: () { state.selectTrack(first); state.setTab(2); },
        child: Row(children: [
          CoverArt(first.image, size: 57, radius: 11),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(first.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(first.artist, style: const TextStyle(color: SoniqColors.muted, fontSize: 11)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(
              value: .63, minHeight: 5, backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(state.accent),
            )),
          ])),
          const SizedBox(width: 10),
          Icon(Icons.play_circle_fill_rounded, size: 34, color: state.accent),
        ]),
      ),
      const SizedBox(height: 22),
      SectionTitle('Playlists', action: '＋', onAction: () => state.setTab(3)),
      SizedBox(height: 150, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.playlists.length - 1,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (context, i) {
          final playlist = state.playlists[i + 1];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist))),
            child: SizedBox(width: 111, child: GlassPanel(padding: const EdgeInsets.all(6), radius: 14, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                CoverArt(playlist.cover, size: 97, radius: 9),
                const SizedBox(height: 5),
                Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${playlist.count} músicas', style: const TextStyle(fontSize: 10, color: SoniqColors.muted)),
              ],
            ))),
          );
        },
      )),
    ]);
  }
}

class _DiscoveryBanner extends StatelessWidget {
  const _DiscoveryBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SoniqColors.purple.withOpacity(.6)),
        image: const DecorationImage(image: AssetImage('assets/covers/discoveries.jpg'), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(.13), const Color(0xED080713)],
        )),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Descobertas da Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text('Playlists personalizadas para você', style: TextStyle(fontSize: 11)),
          ])),
          CircleAvatar(radius: 19, backgroundColor: SoniqColors.violet, child: const Icon(Icons.play_arrow_rounded, color: Colors.white)),
        ]),
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(child: GlassPanel(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
    radius: 13,
    onTap: onTap,
    child: Column(children: [
      Icon(icon, size: 28, color: color),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  ));
}
