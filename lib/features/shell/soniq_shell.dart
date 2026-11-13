import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../../core/widgets/soniq_bottom_nav.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../player/player_screen.dart';
import '../playlists/playlists_screen.dart';
import '../profile/profile_screen.dart';

class SoniqShell extends StatefulWidget {
  const SoniqShell({super.key});

  @override
  State<SoniqShell> createState() => _SoniqShellState();
}

class _SoniqShellState extends State<SoniqShell> {
  bool _showHeadphoneTip = true;
  Timer? _tipTimer;
  Timer? _welcomeTimer;
  bool _welcomeReady = false;
  bool _welcomeVisible = true;

  @override
  void initState() {
    super.initState();
    _welcomeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _welcomeReady = true);
    });
    _tipTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHeadphoneTip = false);
    });
  }

  @override
  void dispose() { _tipTimer?.cancel(); _welcomeTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(
      bottomNavigationBar: state.selectedTab == 2 ? null : const SoniqBottomNav(),
      child: Stack(children: [
        IndexedStack(index: state.selectedTab, children: const [
          HomeScreen(), ExploreScreen(), PlayerScreen(), PlaylistsScreen(), ProfileScreen(),
        ]),
        if (_welcomeVisible)
          Positioned.fill(child: Material(
            color: Colors.black.withOpacity(.76),
            child: Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassPanel(glow: true, opacity: .95, child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.headphones_rounded, color: Color(0xFFBA4DFF), size: 52),
                  const SizedBox(height: 16),
                  const Text('SONIQ 1.0.0 BETA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  const Text('Estamos evoluindo sua experiência musical.', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text('O SONIQ está em fase de desenvolvimento. Algumas funcionalidades podem passar por ajustes enquanto trabalhamos para oferecer a melhor experiência possível.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.5)),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _welcomeReady ? () => setState(() => _welcomeVisible = false) : null,
                    child: Text(_welcomeReady ? 'Continuar para o SONIQ' : 'Aguarde 5 segundos...'),
                  ),
                ],
              )),
            )),
          )),
        if (!_welcomeVisible) Positioned(
          top: 10, left: 20, right: 20,
          child: IgnorePointer(
            ignoring: !_showHeadphoneTip,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              offset: _showHeadphoneTip ? Offset.zero : const Offset(0, -1.8),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _showHeadphoneTip ? 1 : 0,
                child: Material(
                  color: Colors.transparent,
                  child: GlassPanel(
                    glow: true,
                    opacity: .94,
                    child: Row(children: [
                      const Icon(Icons.headphones_rounded, color: Color(0xFF09DCF5), size: 32),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Uma experiência ainda melhor 🎧', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Conecte seus fones de ouvido e aproveite cada detalhe.', style: TextStyle(fontSize: 11)),
                      ])),
                      IconButton(onPressed: () => setState(() => _showHeadphoneTip = false), icon: const Icon(Icons.close_rounded, size: 18)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
