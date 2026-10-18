import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/palette.dart';
import '../../../../core/utils/image_capture.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/states.dart';
import '../../data/book_admin_repository.dart';
import '../../domain/book_history.dart';
import '../../domain/book_suggestion.dart';
import '../../domain/catalog_book.dart';
import '../catalog_book_screen.dart' show BookReportMenu;
import 'book_format.dart';
import 'book_review_widgets.dart';

/// One catalog book for a teacher: details, recommendation for this school,
/// edit, cover, delete or restore, pending suggestions and the history.
class TeacherBookScreen extends ConsumerWidget {
  const TeacherBookScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(adminBookProvider(bookId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail buku'),
        actions: [
          if (book.value?.active ?? false)
            IconButton(
              key: const Key('book-edit'),
              tooltip: 'Ubah data buku',
              onPressed: () => context.push(Routes.teacherEditBook(bookId)),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (book.value != null) BookReportMenu(bookId: bookId),
        ],
      ),
      body: AsyncView<CatalogBook?>(
        value: book,
        onRetry: () => ref.invalidate(adminBookProvider(bookId)),
        data: (book) => book == null
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Buku tidak ditemukan',
              )
            : _BookBody(book: book),
      ),
    );
  }
}

class _BookBody extends ConsumerWidget {
  const _BookBody({required this.book});

  final CatalogBook book;

  Future<void> _changeCover(BuildContext context, WidgetRef ref) async {
    final bytes = await pickAndCropImage(context, shape: ImageCropShape.cover);
    if (bytes == null || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(bookAdminRepositoryProvider).uploadCover(book.id, bytes);
      return true;
    });
    if (ok == true && context.mounted) showSnack(context, 'Cover diganti.');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final choice = await showDeleteBookDialog(
      context,
      bookId: book.id,
      readerCount: book.readerCount,
    );
    if (choice == null || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(bookAdminRepositoryProvider)
          .deleteBook(
            book.id,
            reason: choice.reason,
            duplicateOf: choice.duplicateOf?.id,
          );
      return true;
    });
    if (ok == true && context.mounted) {
      final original = choice.duplicateOf;
      showSnack(
        context,
        original == null
            ? '"${book.title}" dipindah ke Buku terhapus.'
            : '"${book.title}" digabungkan ke "${original.title}".',
      );
    }
  }

  Future<void> _setRecommended(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(bookAdminRepositoryProvider)
          .setRecommended(book.id, recommended: value);
    } catch (error) {
      if (context.mounted) showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recommended =
        ref.watch(schoolRecommendedBooksProvider).value?.contains(book.id) ??
        false;
    final schoolReaders = ref.watch(schoolBookReadersProvider(book.id)).value;
    final suggestions =
        ref.watch(bookSuggestionsProvider(book.id)).value ??
        const <BookSuggestion>[];
    final history = ref.watch(bookHistoryProvider(book.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (!book.active) ...[
          _DeletedBanner(book: book),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: book.active,
              label: book.active ? 'Ganti cover' : null,
              child: InkWell(
                key: const Key('book-cover'),
                borderRadius: BorderRadius.circular(14),
                onTap: book.active ? () => _changeCover(context, ref) : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BookCover(
                      title: book.title,
                      width: 104,
                      coverUrl: book.coverUrl,
                    ),
                    if (book.active)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 16,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: theme.textTheme.titleLarge),
                  if (book.subtitle != null && book.subtitle!.isNotEmpty)
                    Text(
                      book.subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(book.authorLine, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final category in book.categories)
                        _Pill(text: category),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _Fact(label: 'Halaman', value: '${book.pageCount}'),
                _Fact(label: 'Penerbit', value: book.publisher),
                _Fact(
                  label: 'Tahun terbit',
                  value: book.publishedYear?.toString(),
                ),
                _Fact(label: 'ISBN-13', value: book.isbn13),
                _Fact(label: 'ISBN-10', value: book.isbn10),
                _Fact(
                  label: 'Pembaca',
                  value:
                      '${book.readerCount} di semua sekolah'
                      '${schoolReaders == null ? '' : ' · $schoolReaders di sekolah ini'}',
                ),
                _Fact(label: 'Ditambahkan', value: actorLine(book.createdBy)),
                if (book.updatedBy != null)
                  _Fact(
                    label: 'Terakhir diubah',
                    value:
                        '${actorLine(book.updatedBy)} · ${relativeTime(book.updatedAt)}',
                  ),
              ],
            ),
          ),
        ),
        if (book.description != null && book.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Sinopsis', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _ExpandableText(text: book.description!),
        ],
        if (book.active) ...[
          const SizedBox(height: 12),
          _RecommendToggle(
            recommended: recommended,
            onChanged: (value) => _setRecommended(context, ref, value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('book-edit-button'),
                  onPressed: () =>
                      context.push(Routes.teacherEditBook(book.id)),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Ubah'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('book-delete'),
                  onPressed: () => _delete(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Saran menunggu (${suggestions.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EditSuggestionCard(suggestion: suggestion, book: book),
            ),
        ],
        const SizedBox(height: 24),
        Text('Riwayat', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        AsyncView<List<BookHistoryEntry>>(
          value: history,
          loading: const SkeletonList(items: 2, itemHeight: 56),
          data: (entries) => entries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Belum ada riwayat.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, entry) in entries.indexed) ...[
                      if (i > 0) const Divider(),
                      HistoryTile(entry: entry, title: book.title),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// "Dihapus oleh X (Sekolah) pada …" with "Aktifkan kembali".
class _DeletedBanner extends ConsumerWidget {
  const _DeletedBanner({required this.book});

  final CatalogBook book;

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ok = await runWithProgress(context, () async {
      await ref.read(bookAdminRepositoryProvider).restoreBook(book.id);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, '"${book.title}" aktif kembali di katalog.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final text = theme.textTheme.bodyMedium?.copyWith(
      color: palette.inactiveText,
    );
    return Container(
      key: const Key('book-deleted-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.inactiveTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.delete_outline, color: palette.inactiveText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buku ini dihapus',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.inactiveText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Oleh ${actorLine(book.deletedBy)}'
            '${book.deletedAt == null ? '' : ' pada ${fullDateTime(book.deletedAt)}'}.',
            style: text,
          ),
          if (book.deleteReason != null && book.deleteReason!.isNotEmpty)
            Text('Alasan: ${book.deleteReason}', style: text),
          if (book.duplicateOf != null) ...[
            Text(
              'Digabungkan ke buku aslinya. Pembacanya tetap di sana walau '
              'buku ini diaktifkan kembali.',
              style: text,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: palette.inactiveText,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () =>
                    context.push(Routes.teacherBook(book.duplicateOf!)),
                child: const Text('Lihat buku aslinya'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('book-restore'),
              onPressed: () => _restore(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Aktifkan kembali'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null || value!.isEmpty ? '—' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: context.palette.infoTint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: context.palette.info),
    ),
  );
}

/// Long synopses start at five lines with "Selengkapnya".
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final long = widget.text.length > 280;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: style,
          maxLines: _expanded || !long ? null : 5,
          overflow: _expanded || !long ? null : TextOverflow.ellipsis,
        ),
        if (long)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Lebih sedikit' : 'Selengkapnya'),
          ),
      ],
    );
  }
}

/// Recommends the book to this school's students (shown first in their
/// search), or withdraws the recommendation.
class _RecommendToggle extends StatelessWidget {
  const _RecommendToggle({required this.recommended, required this.onChanged});

  final bool recommended;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  recommended ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: recommended
                      ? scheme.tertiary
                      : scheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommended
                            ? 'Direkomendasikan sekolah ini'
                            : 'Belum direkomendasikan',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        'Buku rekomendasi tampil paling atas saat siswa '
                        'mencari.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: recommended
                  ? OutlinedButton.icon(
                      key: const Key('book-recommend'),
                      onPressed: () => onChanged(false),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Batalkan rekomendasi'),
                    )
                  : FilledButton.tonalIcon(
                      key: const Key('book-recommend'),
                      onPressed: () => onChanged(true),
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Rekomendasikan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
