import 'package:flutter/material.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1B1230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(children: [
          Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD76A)),
          SizedBox(width: 10),
          Expanded(child: Text('SONIQ Premium: em breve!', style: TextStyle(fontSize: 18))),
        ]),
        content: const Text(
          'Estamos preparando uma experiência musical ainda mais completa para você. '
          'As assinaturas Premium ainda não estão disponíveis. Em breve, teremos novos recursos e personalizações exclusivas.\n\n'
          'Obrigado por fazer parte do SONIQ! 💜',
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Entendi'),
        )],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => NeonScaffold(child: Column(children: [
    Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      const Expanded(child: PageTitle('Planos SONIQ')),
    ]),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 40), children: [
      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD76A), size: 46),
      const SizedBox(height: 12),
      const Center(child: Text('Sua música, do seu jeito.', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
      const SizedBox(height: 8),
      const Center(child: Text('Conheça os planos do SONIQ', style: TextStyle(color: SoniqColors.muted))),
      const SizedBox(height: 24),
      _planCard(title: 'SONIQ FREE', icon: Icons.headphones_rounded, color: SoniqColors.cyan,
        features: const ['Acesso ao catálogo disponível', 'Reprodução musical', 'Pesquisa de músicas',
          'Favoritos e playlists', 'Perfil e compartilhamento'],
        footer: 'Plano gratuito'),
      const SizedBox(height: 18),
      _planCard(title: 'SONIQ PREMIUM', icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFFFD76A),
        features: const ['Todos os recursos do Free', 'Coroa exclusiva no perfil',
          'Temas e cores especiais', 'Fundos personalizados', 'Letras sincronizadas e karaokê',
          'Recursos avançados do SONIQ CONNECT'],
        footer: 'Em desenvolvimento',
        onPressed: () => _showComingSoon(context)),
      const SizedBox(height: 14),
      const Center(child: Text('Nenhuma cobrança será realizada.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: SoniqColors.muted))),
    ])),
  ]));

  Widget _planCard({required String title, required IconData icon, required Color color,
    required List<String> features, required String footer, VoidCallback? onPressed}) =>
    GlassPanel(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)))]),
      const SizedBox(height: 16),
      for (final feature in features) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
        Icon(Icons.check_circle_outline_rounded, color: color, size: 18),
        const SizedBox(width: 10), Expanded(child: Text(feature, style: const TextStyle(fontSize: 13))),
      ])),
      const SizedBox(height: 8),
      if (onPressed != null) SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: onPressed, icon: const Icon(Icons.workspace_premium_rounded),
        label: const Text('Assinar Premium'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C49E8),
          foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
      )) else Text(footer, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      if (onPressed != null) Padding(padding: const EdgeInsets.only(top: 9),
        child: Text(footer, style: const TextStyle(fontSize: 11, color: SoniqColors.muted))),
    ]));
}
