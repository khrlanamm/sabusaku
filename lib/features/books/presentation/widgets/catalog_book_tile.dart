import 'package:flutter/material.dart';

import '../../../../app/theme/palette.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../domain/catalog_book.dart';

/// One catalog book in a list: cover, title, authors, pages and year, with
/// a "Rekomendasi sekolah" pill when the school recommends it.
class CatalogBookTile extends StatelessWidget {
  const CatalogBookTile({
    super.key,
    required this.entry,
    this.onTap,
    this.recommended = false,
    this.schoolReaders = 0,
    this.trailing,
  });

  final CatalogEntry entry;
  final VoidCallback? onTap;
  final bool recommended;

  /// Students of the signed-in school reading or having read it.
  final int schoolReaders;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final facts = [
      if (entry.pageCount > 0) '${entry.pageCount} hlm',
      if (entry.year != null) '${entry.year}',
      if (schoolReaders > 0) '$schoolReaders siswa di sekolahmu',
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(title: entry.title, coverUrl: entry.coverUrl, width: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (entry.authors.isNotEmpty)
                    Text(
                      entry.authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  if (facts.isNotEmpty)
                    Text(
                      facts,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  if (recommended) ...[
                    const SizedBox(height: 4),
                    const RecommendedPill(),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// "Rekomendasi sekolah", shown on books the school's teachers recommend.
class RecommendedPill extends StatelessWidget {
  const RecommendedPill({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: palette.infoTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: palette.info),
          const SizedBox(width: 4),
          Text(
            'Rekomendasi sekolah',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: palette.info, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
