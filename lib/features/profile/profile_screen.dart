import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';
import 'account_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(19, 36, 19, 116), children: [
      Center(child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 110, height: 110, padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [state.accent, SoniqColors.cyan, state.accent]),
            boxShadow: [BoxShadow(color: state.accent.withOpacity(.44), blurRadius: 27)]),
          child: ClipOval(child: state.avatarUrl != null ? Image.network(state.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/avatars/profile.jpg', fit: BoxFit.cover)) : Image.asset('assets/avatars/profile.jpg', fit: BoxFit.cover)),
        ),
        Positioned(right: -4, bottom: -1, child: CircleGlassButton(icon: Icons.edit_rounded, size: 32,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())))),
      ])),
      const SizedBox(height: 17),
      Center(child: Text(state.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      const SizedBox(height: 3),
      Center(child: Text(state.username, style: const TextStyle(fontSize: 12, color: SoniqColors.muted))),
      const SizedBox(height: 14),
      Center(child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(state.currentUser == null ? 'Modo visitante' : 'Conta SONIQ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      )),
      const SizedBox(height: 20),
      GlassPanel(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), child: Row(children: [
        _Stat(value: '${state.playlists.length}', label: 'Playlists'),
        _Stat(value: '${state.favorites.length}', label: 'Favoritas'),
        _Stat(value: '${state.tracks.where((track) => track.playable).length}', label: 'No catálogo'),
      ])),
      const SizedBox(height: 16),
      _ProfileAction(icon: Icons.login_rounded, label: state.currentUser == null ? 'Entrar ou criar conta' : 'Minha conta', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()))),
      _ProfileAction(icon: Icons.person_outline_rounded, label: 'Editar perfil', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
      _ProfileAction(icon: Icons.info_outline_rounded, label: 'Sobre a versão BETA', onTap: () => showDemoMessage(context, 'SONIQ 1.0.0 BETA: funcionalidades em desenvolvimento.')),
      _ProfileAction(icon: Icons.bar_chart_rounded, label: 'Minhas estatísticas', onTap: () => showDemoMessage(context, 'Estatísticas disponíveis quando o histórico estiver sincronizado.')),
      _ProfileAction(icon: Icons.devices_rounded, label: 'Dispositivos conectados', onTap: () => showDemoMessage(context, 'Dispositivos serão gerenciados pelo serviço de autenticação.')),
      _ProfileAction(icon: Icons.settings_outlined, label: 'Configurações', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: SoniqColors.muted)),
  ]));
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: GlassPanel(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 22),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      const Icon(Icons.chevron_right_rounded, size: 19),
    ]),
  ));
}
