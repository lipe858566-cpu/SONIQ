import '../connect/connect_screen.dart';
import '../plans/plans_screen.dart';
import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../player/equalizer_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/account_screen.dart';
import 'appearance_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(child: Column(children: [
      const PageTitle('Configurações'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(19, 0, 19, 28), children: [
        const _SettingsHeading('Conta'),
        _SettingsRow(icon: Icons.person_outline_rounded, title: 'Editar perfil', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
        _SettingsRow(icon: Icons.lock_outline_rounded, title: 'Segurança', subtitle: 'Senha, verificação e conta', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()))),
        const SizedBox(height: 15),
        const _SettingsHeading('Reprodução'),
        _SettingsRow(icon: Icons.notifications_active_outlined, title: 'Reprodução em segundo plano',
          subtitle: 'Controles na notificação e na tela bloqueada',
          trailing: 'Ativa'),
        _SettingsRow(icon: Icons.tune_rounded, title: 'Equalizador', subtitle: 'Graves, médios, agudos e Bass Boost', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerScreen()))),
        const SizedBox(height: 15),
        const _SettingsHeading('Comunidade'),
        _SettingsRow(icon: Icons.groups_rounded, title: 'SONIQ CONNECT', subtitle: 'Ouça com amigos (em desenvolvimento)', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectScreen()))),
        const SizedBox(height: 15),
        const _SettingsHeading('Planos'),
        _SettingsRow(icon: Icons.workspace_premium_rounded, title: 'SONIQ Free e Premium', subtitle: 'Conheça os benefícios de cada plano', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansScreen()))),
        const SizedBox(height: 15),
        const _SettingsHeading('Aplicativo'),
        _SettingsRow(icon: Icons.settings_suggest_outlined, title: 'Aparência', subtitle: 'Tema, cores e personalização', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen()))),
        const SizedBox(height: 32),
        const Center(child: Text('SONIQ', style: TextStyle(fontSize: 18, letterSpacing: 4, color: SoniqColors.cyan, fontWeight: FontWeight.w900))),
        const SizedBox(height: 5),
        const Center(child: Text('Versão 1.1', style: TextStyle(fontSize: 12, color: SoniqColors.muted))),
        const SizedBox(height: 5),
        const Center(child: Text('As melhores músicas são no SONIQ', style: TextStyle(fontSize: 10, color: SoniqColors.muted))),
      ])),
    ]));
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(label,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)));
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, this.onTap, this.subtitle, this.trailing, this.trailingWidget});
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 5), child: GlassPanel(
    radius: 11, opacity: .4, padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10), onTap: onTap,
    child: Row(children: [
      Icon(icon, size: 20), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: const TextStyle(fontSize: 10, color: SoniqColors.muted))],
      ])),
      if (trailingWidget != null) trailingWidget!
      else if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 11, color: Color(0xFFFFD766)))
      else if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 18),
    ]),
  ));
}
