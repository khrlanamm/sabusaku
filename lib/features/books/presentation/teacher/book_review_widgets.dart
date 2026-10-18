import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/palette.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../data/book_admin_repository.dart';
import '../../domain/book_history.dart';
import '../../domain/book_suggestion.dart';
import '../../domain/catalog_book.dart';
import 'book_format.dart';
import 'book_picker.dart';

/// "Label: from → to". The old value is struck through.
class FieldDiff extends StatelessWidget {
  const FieldDiff({
    super.key,
    required this.field,
    required this.from,
    required this.to,
  });

  final String field;
  final Object? from;
  final Object? to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final before = formatBookValue(field, from);
    final after = formatBookValue(field, to);
    return Semantics(
      label: '${bookFieldLabel(field)}: dari $before menjadi $after',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bookFieldLabel(field),
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: before,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    decoration: before == '—'
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
                // Poppins has no arrow glyph; an icon keeps it crisp.
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextSpan(
                  text: after,
                  style: TextStyle(
                    color: context.palette.activeText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The current cover next to the proposed one.
class CoverDiff extends StatelessWidget {
  const CoverDiff({
    super.key,
    required this.title,
    required this.from,
    required this.to,
  });

  final String title;
  final String? from;
  final String? to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget labelled(String label, String? url) => Column(
      children: [
        BookCover(title: title, width: 64, coverUrl: url),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bookFieldLabel('coverUrl'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            labelled('Sekarang', from),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
            ),
            labelled('Usulan', to),
          ],
        ),
      ],
    );
  }
}

/// One proposed field change, with a value view suited to the field.
Widget proposedChange({
  required String field,
  required String title,
  required Object? from,
  required Object? to,
}) => field == 'coverUrl'
    ? CoverDiff(title: title, from: from as String?, to: to as String?)
    : FieldDiff(field: field, from: from, to: to);

/// A pending `edit` suggestion for [book]: each proposed field with a check
/// box, "Terapkan" for the checked ones and "Tolak".
class EditSuggestionCard extends ConsumerStatefulWidget {
  const EditSuggestionCard({
    super.key,
    required this.suggestion,
    required this.book,
    this.onDone,
  });

  final BookSuggestion suggestion;
  final CatalogBook book;
  final VoidCallback? onDone;

  @override
  ConsumerState<EditSuggestionCard> createState() => _EditSuggestionCardState();
}

class _EditSuggestionCardState extends ConsumerState<EditSuggestionCard> {
  late Set<String> _selected = _fields.toSet();

  /// Proposed fields that still differ from the book (another teacher may
  /// already have applied some of them).
  List<String> get _fields => orderedFields(
    widget.suggestion.proposed.keys.where(
      (field) =>
          // The Storage path of a proposed cover travels with `coverUrl`.
          field != 'coverPath' &&
          formatBookValue(field, widget.suggestion.proposed[field]) !=
              formatBookValue(field, bookFieldValue(widget.book, field)),
    ),
  );

  @override
  void didUpdateWidget(EditSuggestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = _selected.intersection(_fields.toSet());
  }

  Future<void> _apply() async {
    final repository = ref.read(bookAdminRepositoryProvider);
    final all = _selected.length == _fields.length;
    final ok = await runWithProgress(context, () async {
      await repository.applySuggestion(
        widget.suggestion.id,
        fields: all ? null : _selected.toList(),
      );
      return true;
    });
    if (ok == true && mounted) {
      showSnack(context, 'Saran diterapkan ke katalog.');
      widget.onDone?.call();
    }
  }

  Future<void> _reject() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Tolak saran?',
      message:
          'Data buku tidak berubah. Penolakan tercatat di riwayat buku ini.',
      confirmLabel: 'Tolak',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final repository = ref.read(bookAdminRepositoryProvider);
    final ok = await runWithProgress(context, () async {
      await repository.rejectSuggestion(widget.suggestion.id);
      return true;
    });
    if (ok == true && mounted) {
      showSnack(context, 'Saran ditolak.');
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = widget.suggestion;
    final fields = _fields;
    return Card(
      key: Key('suggestion-${suggestion.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${suggestionSourceLine(suggestion.count, suggestion.from.map((s) => s.schoolName))}'
                ' · ${relativeTime(suggestion.updatedAt ?? suggestion.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (fields.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Semua usulan sudah sama dengan data katalog.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            for (final field in fields)
              CheckboxListTile(
                key: Key('suggestion-field-$field'),
                value: _selected.contains(field),
                onChanged: (value) => setState(
                  () => value == true
                      ? _selected.add(field)
                      : _selected.remove(field),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                title: proposedChange(
                  field: field,
                  title: widget.book.title,
                  from: bookFieldValue(widget.book, field),
                  to: suggestion.proposed[field],
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('suggestion-reject'),
                  onPressed: _reject,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Tolak'),
                ),
                FilledButton(
                  key: const Key('suggestion-apply'),
                  onPressed: _selected.isEmpty ? null : _apply,
                  child: Text(
                    _selected.length == fields.length
                        ? 'Terapkan semua'
                        : 'Terapkan ${_selected.length} perubahan',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One entry of a book's history.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, this.title = ''});

  final BookHistoryEntry entry;

  /// The book title, for cover thumbnails.
  final String title;

  static IconData iconOf(BookHistoryType type) => switch (type) {
    BookHistoryType.created => Icons.add_circle_outline,
    BookHistoryType.updated => Icons.edit_outlined,
    BookHistoryType.deleted => Icons.delete_outline,
    BookHistoryType.restored => Icons.restore,
    BookHistoryType.coverChanged => Icons.image_outlined,
    BookHistoryType.suggestionApplied => Icons.task_alt,
    BookHistoryType.suggestionRejected => Icons.block,
    BookHistoryType.merged => Icons.call_merge,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fields = orderedFields(entry.changes.keys);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.infoTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconOf(entry.type),
              size: 18,
              color: context.palette.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.label, style: theme.textTheme.titleSmall),
                Text(
                  '${actorLine(entry.by)} · ${relativeTime(entry.at)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '“${entry.note}”',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: proposedChange(
                      field: field,
                      title: title,
                      from: entry.changes[field]!.from,
                      to: entry.changes[field]!.to,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef DeleteChoice = ({String? reason, CatalogEntry? duplicateOf});

/// Asks why the book is deleted and, optionally, which book it duplicates;
/// the server then merges it into that book. Null when cancelled.
Future<DeleteChoice?> showDeleteBookDialog(
  BuildContext context, {
  required String bookId,
  required int readerCount,
}) => showDialog<DeleteChoice>(
  context: context,
  builder: (_) => _DeleteBookDialog(bookId: bookId, readerCount: readerCount),
);

class _DeleteBookDialog extends StatefulWidget {
  const _DeleteBookDialog({required this.bookId, required this.readerCount});

  final String bookId;

  /// Readers in all schools, who move along when the book is merged.
  final int readerCount;

  @override
  State<_DeleteBookDialog> createState() => _DeleteBookDialogState();
}

class _DeleteBookDialogState extends State<_DeleteBookDialog> {
  final _reason = TextEditingController();
  CatalogEntry? _duplicateOf;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickOriginal() async {
    final picked = await showBookPicker(
      context,
      title: 'Pilih buku aslinya',
      excludeId: widget.bookId,
    );
    if (picked != null) setState(() => _duplicateOf = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final merge = _duplicateOf != null;
    final readers = widget.readerCount == 0
        ? 'Buku ini belum punya pembaca. '
        : '${widget.readerCount} pembacanya di semua sekolah, beserta '
              'jurnal mereka, pindah ke buku aslinya. ';
    return AlertDialog(
      title: Text(merge ? 'Gabungkan buku?' : 'Hapus buku?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              merge
                  ? 'Buku ini pindah ke "Buku terhapus". '
                        '$readers'
                        'Rekomendasi sekolah juga pindah. Penggabungan tetap '
                        'berlaku walau buku ini diaktifkan kembali.'
                  : 'Buku pindah ke "Buku terhapus" dan tidak muncul di '
                        'pencarian siswa. Penanggung jawab sekolah mana pun '
                        'bisa mengaktifkannya kembali. Siswa yang sudah '
                        'membacanya tidak terpengaruh.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('delete-reason'),
              controller: _reason,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Alasan (opsional)',
                hintText: 'Misalnya: data salah, bukan buku',
              ),
            ),
            const SizedBox(height: 4),
            if (_duplicateOf == null)
              OutlinedButton.icon(
                key: const Key('delete-pick-original'),
                onPressed: _pickOriginal,
                icon: const Icon(Icons.call_merge),
                label: const Text('Gabungkan ke buku asli…'),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: BookCover(
                    title: _duplicateOf!.title,
                    width: 32,
                    coverUrl: _duplicateOf!.coverUrl,
                  ),
                  title: Text(
                    'Gabungkan ke ${_duplicateOf!.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_duplicateOf!.authors),
                  trailing: IconButton(
                    tooltip: 'Batalkan pilihan',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _duplicateOf = null),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop((
            reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
            duplicateOf: _duplicateOf,
          )),
          child: Text(merge ? 'Gabungkan' : 'Hapus'),
        ),
      ],
    );
  }
}
