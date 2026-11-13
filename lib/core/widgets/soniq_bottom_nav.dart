import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/soniq_controller.dart';
import '../theme/soniq_theme.dart';

class SoniqBottomNav extends StatelessWidget {
  const SoniqBottomNav({super.key});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.search_rounded, Icons.search_rounded, 'Explorar'),
    (Icons.graphic_eq_rounded, Icons.graphic_eq_rounded, 'Player'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favoritos'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = SoniqScope.of(context);
    final accent = state.accent;
    final opacity = (1 - state.navTransparency).clamp(.15, .85).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 67,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF28143E).withOpacity(opacity + .1),
              const Color(0xFF111329).withOpacity(opacity),
            ]),
            border: Border.all(color: accent.withOpacity(.38)),
            borderRadius: BorderRadius.circular(21),
            boxShadow: [BoxShadow(color: accent.withOpacity(.18), blurRadius: 19)],
          ),
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  state.setTab(i);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(state.selectedTab == i ? _items[i].$2 : _items[i].$1,
                    size: 22,
                    color: state.selectedTab == i ? accent : Colors.white.withOpacity(.82),
                    shadows: state.selectedTab == i ? [Shadow(color: accent, blurRadius: 13)] : null),
                  const SizedBox(height: 3),
                  Text(_items[i].$3, style: TextStyle(fontSize: 10,
                    fontWeight: state.selectedTab == i ? FontWeight.w700 : FontWeight.w400,
                    color: state.selectedTab == i ? Colors.white : SoniqColors.muted)),
                ]),
              )),
          ]),
        ),
      ),
    );
  }
}
