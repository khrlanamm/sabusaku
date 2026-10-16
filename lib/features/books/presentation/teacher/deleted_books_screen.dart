import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/states.dart';
import '../../data/book_admin_repository.dart';
import '../../domain/catalog_book.dart';
import 'book_format.dart';

/// Books removed from the catalog. Any teacher of any school can bring one
/// back; nothing here is ever deleted for good.
class DeletedBooksScreen extends ConsumerWidget {
  const DeletedBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(deletedBooksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Buku terhapus')),
      body: AsyncView<List<CatalogBook>>(
        value: books,
        onRetry: () => ref.invalidate(deletedBooksProvider),
        data: (books) => books.isEmpty
            ? const EmptyState(
                icon: Icons.auto_delete_outlined,
                title: 'Tidak ada buku terhapus',
                message:
                    'Buku yang dihapus penanggung jawab muncul di sini dan '
                    'bisa diaktifkan kembali.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: books.length + 1,
                separatorBuilder: (_, i) => i == 0
                    ? const SizedBox.shrink()
                    : const Divider(indent: 76),
                itemBuilder: (context, i) => i == 0
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'Penanggung jawab sekolah mana pun bisa mengaktifkan '
                          'kembali buku di sini. Siswa yang sudah membacanya '
                          'tidak terpengaruh.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      )
                    : _DeletedBookTile(book: books[i - 1]),
              ),
      ),
    );
  }
}

class _DeletedBookTile extends ConsumerWidget {
  const _DeletedBookTile({required this.book});

  final CatalogBook book;

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Aktifkan kembali?',
      message: '"${book.title}" kembali muncul di katalog dan pencarian siswa.',
      confirmLabel: 'Aktifkan',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(bookAdminRepositoryProvider).restoreBook(book.id);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, '"${book.title}" aktif kembali.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return InkWell(
      key: Key('deleted-${book.id}'),
      onTap: () => context.push(Routes.teacherBook(book.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(title: book.title, width: 44, coverUrl: book.coverUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    book.authorLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dihapus ${actorLine(book.deletedBy)} · '
                    '${relativeTime(book.deletedAt)}',
                    style: muted,
                  ),
                  if (book.deleteReason != null &&
                      book.deleteReason!.isNotEmpty)
                    Text('Alasan: ${book.deleteReason}', style: muted),
                  if (book.duplicateOf != null)
                    Text('Ditandai sebagai duplikat', style: muted),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: Key('restore-${book.id}'),
              onPressed: () => _restore(context, ref),
              child: const Text('Aktifkan'),
            ),
          ],
        ),
      ),
    );
  }
}
