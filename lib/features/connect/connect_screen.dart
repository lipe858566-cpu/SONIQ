import 'package:flutter/material.dart';
import '../../core/theme/soniq_theme.dart';
import '../../core/widgets/neon_scaffold.dart';


class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) => NeonScaffold(
    child: Column(children: [
      const PageTitle('SONIQ CONNECT'),
      Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 24),
        const Center(child: Icon(Icons.groups_rounded, size: 76, color: Color(0xFFB47AFF))),
        const SizedBox(height: 20),
        const Center(child: Text('Ouça junto, mesmo à distância',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
        const SizedBox(height: 14),
        const Text('Em breve, você poderá criar salas, convidar amigos e sincronizar a reprodução em tempo real.',
          textAlign: TextAlign.center, style: TextStyle(color: SoniqColors.muted, height: 1.5)),
        const SizedBox(height: 28),
        GlassPanel(padding: const EdgeInsets.all(18), child: Column(children: [
          const Icon(Icons.construction_rounded, color: Color(0xFFFFD766), size: 30),
          const SizedBox(height: 10),
          const Text('Função em desenvolvimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Estamos preparando salas seguras e reprodução sincronizada. O SONIQ CONNECT será liberado em uma futura atualização.',
            textAlign: TextAlign.center, style: TextStyle(color: SoniqColors.muted)),
        ])),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: null, icon: Icon(Icons.add_rounded), label: Text('Criar sala (em breve)')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: null, icon: Icon(Icons.login_rounded), label: Text('Entrar em sala (em breve)')),
      ])),
    ]),
  );
}
