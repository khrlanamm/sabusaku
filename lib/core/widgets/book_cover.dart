import 'package:flutter/material.dart';

/// Automatic cover: a colour derived from the title plus its initials.
/// V1 has no cover upload (PRD §4).
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.title, this.width = 64});

  final String title;
  final double width;

  static const _palette = <List<Color>>[
    [Color(0xFF2563EB), Color(0xFF1D4FC4)],
    [Color(0xFF17365D), Color(0xFF0F2747)],
    [Color(0xFF2FA866), Color(0xFF1E7A49)],
    [Color(0xFF7C4DDB), Color(0xFF5A2FB5)],
    [Color(0xFFD9722B), Color(0xFFB0531A)],
    [Color(0xFFC0392B), Color(0xFF962A1F)],
    [Color(0xFF0E8C8C), Color(0xFF096666)],
  ];

  /// Up to two initials from the first two words of the title.
  static String initialsOf(String title) {
    final words = title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
  }

  /// Stable across runs, unlike [String.hashCode].
  static int paletteIndexOf(String title) {
    var hash = 0;
    for (final unit in title.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % _palette.length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palette[paletteIndexOf(title)];
    return Semantics(
      label: 'Sampul buku $title',
      excludeSemantics: true,
      child: Container(
        width: width,
        height: width * 1.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(width * 0.14),
        ),
        alignment: Alignment.center,
        child: Text(
          initialsOf(title),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: width * 0.34,
          ),
        ),
      ),
    );
  }
}
