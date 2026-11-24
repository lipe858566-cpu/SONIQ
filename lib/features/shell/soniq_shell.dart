import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/state/soniq_controller.dart';
import '../../core/widgets/neon_scaffold.dart';
import '../../core/widgets/mini_player.dart';
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
  @override
  void initState() {
    super.initState();
    _tipTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHeadphoneTip = false);
    });
  }

  @override
  void dispose() { _tipTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    return NeonScaffold(
      bottomNavigationBar: state.selectedTab == 2
          ? null
          : const Column(mainAxisSize: MainAxisSize.min, children: [MiniPlayer(), SoniqBottomNav()]),
      child: Stack(children: [
        IndexedStack(index: state.selectedTab, children: const [
          HomeScreen(), ExploreScreen(), PlayerScreen(), PlaylistsScreen(), ProfileScreen(),
        ]),
        Positioned(
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
