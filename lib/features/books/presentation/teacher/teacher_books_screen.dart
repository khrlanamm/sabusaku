import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/states.dart';
import '../../data/book_admin_repository.dart';
import '../../data/catalog_repository.dart';
import '../../domain/book_categories.dart';
import '../../domain/catalog_book.dart';
import 'book_picker.dart';

/// The shared book catalog as a teacher sees it: search, category filter,
/// this school's recommendations, and the way to suggestions and deleted
/// books.
class TeacherBooksScreen extends ConsumerStatefulWidget {
  const TeacherBooksScreen({super.key});

  @override
  ConsumerState<TeacherBooksScreen> createState() => _TeacherBooksScreenState();
}

class _TeacherBooksScreenState extends ConsumerState<TeacherBooksScreen> {
  final _query = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(catalogIndexProvider);
    final recommended =
        ref.watch(schoolRecommendedBooksProvider).value ?? const <String>[];
    final pending = ref.watch(pendingSuggestionsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Buku'),
        actions: [
          IconButton(
            key: const Key('books-suggestions'),
            tooltip: 'Saran dari siswa',
            onPressed: () => context.push(Routes.teacherSuggestions),
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.inbox_outlined),
            ),
          ),
          IconButton(
            key: const Key('books-deleted'),
            tooltip: 'Buku terhapus',
            onPressed: () => context.push(Routes.teacherDeletedBooks),
            icon: const Icon(Icons.auto_delete_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('books-add'),
        onPressed: () => context.push(Routes.teacherAddBook),
        icon: const Icon(Icons.add),
        label: const Text('Tambah buku'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: const Key('books-search'),
              controller: _query,
              decoration: InputDecoration(
                hintText: 'Cari judul atau penulis',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final category in [null, ...bookCategories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category ?? 'Semua'),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<CatalogEntry>>(
              value: index,
              onRetry: () => ref.invalidate(catalogIndexProvider),
              data: (entries) => _CatalogList(
                entries: entries,
                query: _query.text,
                category: _category,
                recommended: recommended.toSet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.entries,
    required this.query,
    required this.category,
    required this.recommended,
  });

  final List<CatalogEntry> entries;
  final String query;
  final String? category;
  final Set<String> recommended;

  @override
  Widget build(BuildContext context) {
    // While browsing, recommendations get their own section on top; in a
    // search they rank first among the matches.
    final browsing = query.trim().isEmpty && category == null;
    final results = searchCatalog(
      entries,
      query,
      category: category,
      recommended: browsing ? const [] : recommended.toList(),
    );
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: entries.isEmpty
            ? 'Katalog masih kosong'
            : 'Buku tidak ditemukan',
        message: 'Tambahkan buku baru dengan tombol "Tambah buku".',
      );
    }
    final picks = browsing
        ? results.where((e) => recommended.contains(e.id)).toList()
        : const <CatalogEntry>[];

    final rows = <Widget Function(BuildContext)>[
      if (picks.isNotEmpty) ...[
        (_) => const _SectionHeader('Rekomendasi sekolah'),
        for (final entry in picks) (c) => _tile(c, entry),
      ],
      (_) => _SectionHeader(
        browsing ? 'Semua buku (${results.length})' : '${results.length} buku',
      ),
      for (final entry in results) (c) => _tile(c, entry),
    ];
    return ListView.builder(
      key: const Key('books-list'),
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i](context),
    );
  }

  Widget _tile(BuildContext context, CatalogEntry entry) => TeacherBookTile(
    entry: entry,
    recommended: recommended.contains(entry.id),
    onTap: () => context.push(Routes.teacherBook(entry.id)),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
