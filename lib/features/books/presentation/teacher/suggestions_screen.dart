import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/palette.dart';
import '../../../../core/models/report.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/report_sheet.dart';
import '../../../../core/widgets/states.dart';
import '../../data/book_admin_repository.dart';
import '../../data/catalog_repository.dart';
import '../../domain/book_suggestion.dart';
import '../../domain/catalog_book.dart';
import 'book_editor_screen.dart';
import 'book_format.dart';
import 'book_picker.dart';
import 'book_review_widgets.dart';

/// Every pending suggestion from students of all schools, newest first.
class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(pendingSuggestionsProvider);
    final index = ref.watch(catalogIndexProvider).value ?? const [];
    final titles = {for (final entry in index) entry.id: entry};
    return Scaffold(
      appBar: AppBar(title: const Text('Saran dari siswa')),
      body: AsyncView<List<BookSuggestion>>(
        value: suggestions,
        onRetry: () => ref.invalidate(pendingSuggestionsProvider),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Tidak ada saran yang menunggu',
                message:
                    'Saran muncul saat siswa mengubah data buku dari katalog '
                    'atau menambah buku yang belum ada.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(indent: 76),
                itemBuilder: (context, i) => _SuggestionTile(
                  suggestion: items[i],
                  book: titles[items[i].bookId],
                ),
              ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, this.book});

  final BookSuggestion suggestion;

  /// The catalog entry an `edit` suggestion is about.
  final CatalogEntry? book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = suggestion.kind == SuggestionKind.newBook;
    final title =
        (isNew ? suggestion.proposed['title'] : book?.title) as String? ??
        suggestion.proposed['title'] as String? ??
        'Buku';
    final fields = orderedFields(suggestion.proposed.keys)
        .where((f) => f != 'coverPath')
        .map(bookFieldLabel)
        .join(', ');
    return ListTile(
      key: Key('suggestion-tile-${suggestion.id}'),
      onTap: () => context.push(Routes.teacherSuggestion(suggestion.id)),
      leading: BookCover(
        title: title,
        width: 40,
        coverUrl: isNew
            ? suggestion.proposed['coverUrl'] as String?
            : book?.coverUrl,
      ),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _KindPill(isNew: isNew),
          const SizedBox(height: 4),
          if (!isNew && fields.isNotEmpty) Text('Usulan: $fields'),
          Text(
            '${suggestionSourceLine(suggestion.count, suggestion.from.map((s) => s.schoolName))}'
            ' · ${relativeTime(suggestion.updatedAt ?? suggestion.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.isNew});

  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (fg, bg) = isNew
        ? (palette.activeText, palette.activeTint)
        : (palette.info, palette.infoTint);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isNew ? 'Buku baru' : 'Ubah data',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// One suggestion. `edit`: the proposed changes against the catalog book.
/// `new`: add it to the catalog, merge it into an existing book, or reject.
class SuggestionReviewScreen extends ConsumerWidget {
  const SuggestionReviewScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(suggestionProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinjau saran'),
        actions: [
          if (suggestion.value != null)
            PopupMenuButton<ReportTarget>(
              key: const Key('suggestion-menu'),
              tooltip: 'Lainnya',
              onSelected: (target) =>
                  showReportSheet(context, ref, target: target),
              itemBuilder: (_) => [
                PopupMenuItem(
                  key: const Key('suggestion-report'),
                  value: ReportTarget.suggestion(id),
                  child: const Text('Laporkan saran'),
                ),
              ],
            ),
        ],
      ),
      body: AsyncView<BookSuggestion?>(
        value: suggestion,
        onRetry: () => ref.invalidate(suggestionProvider(id)),
        data: (suggestion) {
          if (suggestion == null) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Saran tidak ditemukan',
            );
          }
          if (!suggestion.pending) return _Reviewed(suggestion: suggestion);
          return suggestion.kind == SuggestionKind.edit
              ? _EditReview(suggestion: suggestion)
              : _NewBookReview(suggestion: suggestion);
        },
      ),
    );
  }
}

/// Shown when another teacher already handled the suggestion.
class _Reviewed extends StatelessWidget {
  const _Reviewed({required this.suggestion});

  final BookSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final accepted = suggestion.status == SuggestionStatus.accepted;
    final bookId = suggestion.resultBookId ?? suggestion.bookId;
    return EmptyState(
      icon: accepted ? Icons.task_alt : Icons.block,
      title: accepted ? 'Saran sudah diterapkan' : 'Saran sudah ditolak',
      message:
          'Oleh ${actorLine(suggestion.reviewedBy)}'
          '${suggestion.reviewedAt == null ? '' : ', ${relativeTime(suggestion.reviewedAt)}'}.',
      action: bookId == null
          ? null
          : OutlinedButton(
              onPressed: () => context.push(Routes.teacherBook(bookId)),
              child: const Text('Buka buku'),
            ),
    );
  }
}

class _EditReview extends ConsumerWidget {
  const _EditReview({required this.suggestion});

  final BookSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookId = suggestion.bookId!;
    final book = ref.watch(adminBookProvider(bookId));
    return AsyncView<CatalogBook?>(
      value: book,
      data: (book) {
        if (book == null) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Buku katalog tidak ditemukan',
          );
        }
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(Routes.teacherBook(book.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    BookCover(
                      title: book.title,
                      width: 56,
                      coverUrl: book.coverUrl,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title, style: theme.textTheme.titleMedium),
                          Text(
                            book.authorLine,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (!book.active)
                            Text(
                              'Buku ini sedang dihapus',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pilih perubahan yang benar, lalu terapkan. Data katalog berubah '
              'untuk semua sekolah dan tercatat di riwayat buku.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            EditSuggestionCard(suggestion: suggestion, book: book),
          ],
        );
      },
    );
  }
}

class _NewBookReview extends ConsumerWidget {
  const _NewBookReview({required this.suggestion});

  final BookSuggestion suggestion;

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    final picked = await showBookPicker(
      context,
      title: 'Gabungkan ke buku yang ada',
    );
    if (picked == null || !context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Gabungkan saran?',
      message:
          'Saran ini dianggap sama dengan "${picked.title}". Data katalog '
          'tidak berubah.',
      confirmLabel: 'Gabungkan',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(bookAdminRepositoryProvider)
          .linkSuggestion(suggestion.id, picked.id);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Saran digabungkan ke "${picked.title}".');
      context.pop();
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Tolak saran?',
      message: 'Buku ini tidak ditambahkan ke katalog.',
      confirmLabel: 'Tolak',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(bookAdminRepositoryProvider)
          .rejectSuggestion(suggestion.id);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Saran ditolak.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final proposed = suggestion.proposed;
    final title = proposed['title'] as String? ?? 'Buku';
    final coverUrl = proposed['coverUrl'] as String?;
    final fields = orderedFields(proposed.keys)
        .where((f) => f != 'coverUrl' && f != 'coverPath');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'Siswa menambahkan buku yang belum ada di katalog.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${suggestionSourceLine(suggestion.count, suggestion.from.map((s) => s.schoolName))}'
          ' · ${relativeTime(suggestion.updatedAt ?? suggestion.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(title: title, width: 72, coverUrl: coverUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final field in fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookFieldLabel(field),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                formatBookValue(field, proposed[field]),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('suggestion-create'),
          onPressed: () => context.push(
            Routes.teacherAddBook,
            extra: BookEditorSeed(
              suggestionId: suggestion.id,
              fields: proposed,
              coverUrl: coverUrl,
            ),
          ),
          icon: const Icon(Icons.library_add_outlined),
          label: const Text('Tambahkan ke katalog'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('suggestion-link'),
          onPressed: () => _link(context, ref),
          icon: const Icon(Icons.merge_type),
          label: const Text('Gabungkan ke buku yang ada'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('suggestion-reject-new'),
          onPressed: () => _reject(context, ref),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
