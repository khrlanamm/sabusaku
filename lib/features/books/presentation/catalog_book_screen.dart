import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/models/report.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/report_sheet.dart';
import '../../../core/widgets/states.dart';
import '../../student/data/student_repository.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_book.dart';
import 'widgets/catalog_book_tile.dart';

/// One catalog book as a student sees it, with "Baca buku ini".
class CatalogBookScreen extends ConsumerWidget {
  const CatalogBookScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(catalogBookProvider(bookId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail buku'),
        actions: [if (book.value != null) BookReportMenu(bookId: bookId)],
      ),
      body: AsyncView<CatalogBook?>(
        value: book,
        onRetry: () => ref.invalidate(catalogBookProvider(bookId)),
        data: (book) => book == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Buku tidak ditemukan',
                message: 'Buku ini tidak ada di katalog.',
              )
            : _BookDetail(book: book),
      ),
    );
  }
}

/// App bar overflow with "Laporkan buku", shared with the teacher's book
/// screen.
class BookReportMenu extends ConsumerWidget {
  const BookReportMenu({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<ReportTarget>(
        key: const Key('book-menu'),
        tooltip: 'Lainnya',
        onSelected: (target) => showReportSheet(context, ref, target: target),
        itemBuilder: (_) => [
          PopupMenuItem(
            key: const Key('book-report'),
            value: ReportTarget.book(bookId),
            child: const Text('Laporkan buku'),
          ),
        ],
      );
}

class _BookDetail extends ConsumerWidget {
  const _BookDetail({required this.book});

  final CatalogBook book;

  void _read(BuildContext context, WidgetRef ref) {
    ref.read(pendingBookPickProvider.notifier).pick(entryOfBook(book));
    context.go(Routes.studentBook);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final recommended = ref.watch(recommendedBookIdsProvider).contains(book.id);
    final schoolReaders =
        ref.watch(schoolBookStatsProvider).value?[book.id]?.readers ?? 0;
    final active = ref.watch(activeProgramProvider).value;
    final canStart = book.active && active == null;

    final facts = [
      if (book.publisher != null && book.publisher!.isNotEmpty)
        ('Penerbit', book.publisher!),
      if (book.publishedYear != null) ('Tahun terbit', '${book.publishedYear}'),
      if (book.pageCount > 0) ('Halaman', '${book.pageCount}'),
      if (book.isbn13 != null || book.isbn10 != null)
        ('ISBN', book.isbn13 ?? book.isbn10!),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: BookCover(
              title: book.title,
              coverUrl: book.coverUrl,
              width: 140,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          book.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (book.subtitle != null && book.subtitle!.isNotEmpty)
          Text(
            book.subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: muted),
          ),
        const SizedBox(height: 4),
        Text(
          book.authorLine,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (recommended) const RecommendedPill(),
            for (final category in book.categories)
              Chip(label: Text(category), visualDensity: VisualDensity.compact),
          ],
        ),
        if (!book.active) ...[
          const SizedBox(height: 16),
          _Banner(
            icon: Icons.info_outline,
            text: 'Buku ini sudah dihapus dari katalog.',
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.groups_outlined, color: context.palette.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        book.readerCount == 0
                            ? 'Belum ada yang membaca. Jadilah yang pertama!'
                            : 'Dibaca ${book.readerCount} siswa'
                                  '${schoolReaders > 0 ? ', $schoolReaders di sekolahmu' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (facts.isNotEmpty) const Divider(height: 28),
                for (final (label, value) in facts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (book.description != null &&
            book.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Sinopsis', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _Synopsis(text: book.description!.trim()),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('catalog-read'),
          onPressed: canStart ? () => _read(context, ref) : null,
          icon: const Icon(Icons.auto_stories_outlined),
          label: const Text('Baca buku ini'),
        ),
        if (book.active && active != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Kamu sedang membaca "${active.book.title}". Selesaikan atau '
              'hentikan dulu untuk memulai buku lain.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
      ],
    );
  }
}

/// The synopsis, folded to six lines until "Selengkapnya".
class _Synopsis extends StatefulWidget {
  const _Synopsis({required this.text});

  final String text;

  @override
  State<_Synopsis> createState() => _SynopsisState();
}

class _SynopsisState extends State<_Synopsis> {
  static const _foldedLines = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _foldedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _foldedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (long)
              TextButton(
                key: const Key('catalog-synopsis-toggle'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Tutup' : 'Selengkapnya'),
              ),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.neutralTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.neutralText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.neutralText),
            ),
          ),
        ],
      ),
    );
  }
}
