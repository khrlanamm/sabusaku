import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/states.dart';
import '../../data/catalog_repository.dart';
import '../../domain/catalog_book.dart';

/// One catalog entry in a teacher list: cover, title, authors, pages and
/// readers.
class TeacherBookTile extends StatelessWidget {
  const TeacherBookTile({
    super.key,
    required this.entry,
    this.onTap,
    this.recommended = false,
    this.trailing,
  });

  final CatalogEntry entry;
  final VoidCallback? onTap;
  final bool recommended;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final details = [
      '${entry.pageCount} hal.',
      if (entry.year != null) '${entry.year}',
      if (entry.readerCount > 0) '${entry.readerCount} pembaca',
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            BookCover(title: entry.title, width: 44, coverUrl: entry.coverUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: theme.colorScheme.tertiary,
                          semanticLabel: 'Rekomendasi sekolah',
                        ),
                      ],
                    ],
                  ),
                  if (entry.authors.isNotEmpty)
                    Text(
                      entry.authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(details, style: muted),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Lets the teacher pick an active catalog book, e.g. the original of a
/// duplicate. Returns null when dismissed.
Future<CatalogEntry?> showBookPicker(
  BuildContext context, {
  String title = 'Pilih buku',
  String? excludeId,
}) => showModalBottomSheet<CatalogEntry>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _BookPickerSheet(title: title, excludeId: excludeId),
);

class _BookPickerSheet extends ConsumerStatefulWidget {
  const _BookPickerSheet({required this.title, this.excludeId});

  final String title;
  final String? excludeId;

  @override
  ConsumerState<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends ConsumerState<_BookPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(catalogIndexProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('book-picker-search'),
                  controller: _query,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Cari judul atau penulis',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<CatalogEntry>>(
              value: index,
              data: (entries) {
                final results = searchCatalog(
                  entries,
                  _query.text,
                  limit: 101,
                ).where((e) => e.id != widget.excludeId).take(100).toList();
                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Buku tidak ditemukan',
                    message: 'Coba kata lain dari judul atau nama penulis.',
                  );
                }
                return ListView.builder(
                  controller: controller,
                  itemCount: results.length,
                  itemBuilder: (context, i) => TeacherBookTile(
                    entry: results[i],
                    onTap: () => Navigator.of(context).pop(results[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
