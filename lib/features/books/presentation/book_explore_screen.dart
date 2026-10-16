import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/states.dart';
import '../data/catalog_repository.dart';
import '../domain/book_categories.dart';
import '../domain/catalog_book.dart';
import 'widgets/book_search_field.dart';
import 'widgets/catalog_book_tile.dart';

/// "Jelajahi katalog": the shared book catalog for students, with the
/// school's recommendations and what classmates read.
class BookExploreScreen extends ConsumerStatefulWidget {
  const BookExploreScreen({super.key});

  @override
  ConsumerState<BookExploreScreen> createState() => _BookExploreScreenState();
}

class _BookExploreScreenState extends ConsumerState<BookExploreScreen> {
  final _query = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(CatalogEntry entry) =>
      context.push(Routes.studentCatalogBook(entry.id));

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(catalogIndexProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Jelajahi katalog')),
      body: switch (index) {
        AsyncError(:final error) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Katalog belum bisa dibuka',
          message: error == catalogNotLoaded
              ? catalogNotLoaded.userMessage
              : 'Periksa koneksi internetmu, lalu coba lagi.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(catalogIndexProvider),
            child: const Text('Coba lagi'),
          ),
        ),
        AsyncData(:final value) when value.isEmpty => const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Katalog masih kosong',
          message: 'Penanggung jawab sekolah sedang menyiapkan daftar buku.',
        ),
        AsyncData(:final value) => _content(value),
        _ => const SkeletonList(),
      },
    );
  }

  Widget _content(List<CatalogEntry> entries) {
    final theme = Theme.of(context);
    final recommended = ref.watch(recommendedBookIdsProvider);
    final schoolReaders = {
      for (final MapEntry(:key, :value)
          in (ref.watch(schoolBookStatsProvider).value ?? const {}).entries)
        key: value.readers,
    };
    final query = _query.text.trim();
    final filtering = query.isNotEmpty || _category != null;

    final results = searchCatalog(
      entries,
      query,
      category: _category,
      recommended: recommended,
      schoolReaders: schoolReaders,
    );
    final picks = filtering
        ? const <CatalogEntry>[]
        : searchCatalog(
            entries.where((entry) => recommended.contains(entry.id)).toList(),
            '',
            recommended: recommended,
            schoolReaders: schoolReaders,
          );
    final popular = filtering
        ? const <CatalogEntry>[]
        : (entries.where((entry) => (schoolReaders[entry.id] ?? 0) > 0).toList()
                ..sort(
                  (a, b) => (schoolReaders[b.id] ?? 0).compareTo(
                    schoolReaders[a.id] ?? 0,
                  ),
                ))
              .take(10)
              .toList();

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverToBoxAdapter(
            child: BookSearchField(
              fieldKey: const Key('explore-search'),
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final category in [null, ...bookCategories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('explore-category-${category ?? 'semua'}'),
                      label: Text(category ?? 'Semua'),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (picks.isNotEmpty)
          _Shelf(title: 'Rekomendasi sekolah', entries: picks, onOpen: _open),
        if (popular.isNotEmpty)
          _Shelf(
            title: 'Populer di sekolahmu',
            entries: popular,
            onOpen: _open,
            caption: (entry) => '${schoolReaders[entry.id]} siswa',
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              filtering
                  ? '${results.length} buku ditemukan'
                  : 'Semua buku (${entries.length})',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada buku yang cocok. Coba kata lain, atau isi data '
                'bukumu sendiri di halaman Mulai Buku.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverList.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final entry = results[index];
                return CatalogBookTile(
                  key: Key('explore-book-$index'),
                  entry: entry,
                  recommended: recommended.contains(entry.id),
                  schoolReaders: schoolReaders[entry.id] ?? 0,
                  onTap: () => _open(entry),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// A horizontal row of covers with a heading.
class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.title,
    required this.entries,
    required this.onOpen,
    this.caption,
  });

  final String title;
  final List<CatalogEntry> entries;
  final ValueChanged<CatalogEntry> onOpen;
  final String Function(CatalogEntry entry)? caption;

  static const _coverWidth = 92.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          SizedBox(
            height: _coverWidth * 1.4 + 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return SizedBox(
                  width: _coverWidth,
                  child: InkWell(
                    onTap: () => onOpen(entry),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookCover(
                          title: entry.title,
                          coverUrl: entry.coverUrl,
                          width: _coverWidth,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                        Text(
                          caption?.call(entry) ?? entry.authors,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
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
