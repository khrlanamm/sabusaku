import 'package:flutter/material.dart';

/// A book cover. Shows [coverUrl] when the book has one (catalog books),
/// fading in over the automatic cover; otherwise, or when the image cannot
/// load, the automatic cover: a colour derived from the title plus its
/// initials.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.width = 64,
    this.coverUrl,
  });

  final String title;
  final double width;
  final String? coverUrl;

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

  double get _height => width * 1.4;

  BorderRadius get _radius => BorderRadius.circular(width * 0.14);

  Widget _generated(Border? edge) {
    final colors = _palette[paletteIndexOf(title)];
    return Container(
      width: width,
      height: _height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: _radius,
        border: edge,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dark covers would melt into dark surfaces without an edge.
    final edge = theme.brightness == Brightness.dark
        ? Border.all(color: theme.colorScheme.outline)
        : null;
    final url = coverUrl;
    final generated = _generated(edge);
    final Widget cover;
    if (url == null || url.isEmpty) {
      cover = generated;
    } else {
      final pixels = (width * MediaQuery.devicePixelRatioOf(context)).round();
      final image = ClipRRect(
        borderRadius: _radius,
        child: Image.network(
          url,
          width: width,
          height: _height,
          fit: BoxFit.cover,
          cacheWidth: pixels,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, synchronous) {
            if (synchronous) return child;
            return Stack(
              fit: StackFit.passthrough,
              children: [
                generated,
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: child,
                ),
              ],
            );
          },
          errorBuilder: (_, _, _) => generated,
        ),
      );
      cover = edge == null
          ? image
          : DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(border: edge, borderRadius: _radius),
              child: image,
            );
    }

    return Semantics(
      label: 'Sampul buku $title',
      excludeSemantics: true,
      child: SizedBox(width: width, height: _height, child: cover),
    );
  }
}
