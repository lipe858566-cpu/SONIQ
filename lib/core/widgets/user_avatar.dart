import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.url, required this.size});
  final String? url;
  final double size;

  Widget placeholder() => ColoredBox(
    color: const Color(0xFF211831),
    child: Center(child: Icon(Icons.person_rounded, size: size * .65,
      color: const Color(0xFFB8ACC9))),
  );

  @override
  Widget build(BuildContext context) {
    final address = url;
    return ClipOval(child: SizedBox(width: size, height: size,
      child: address == null || address.isEmpty ? placeholder() : Image.network(
        address, key: ValueKey(address), fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, __, ___) => placeholder(),
        frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : placeholder(),
      ),
    ));
  }
}
