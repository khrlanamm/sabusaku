import 'package:flutter/material.dart';

/// A profile photo, or the first letter of the name while there is none or
/// the photo cannot load.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
  });

  final String? photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    final url = photoUrl;
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      // Without a handler a broken URL throws; the initial stays visible.
      onForegroundImageError: url == null || url.isEmpty ? null : (_, _) {},
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
