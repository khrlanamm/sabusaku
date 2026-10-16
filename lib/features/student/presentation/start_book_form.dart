import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/utils/image_capture.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/dialogs.dart';
import '../../books/data/catalog_repository.dart';
import '../../books/domain/catalog_book.dart';
import '../../books/presentation/widgets/book_search_field.dart';
import '../../books/presentation/widgets/catalog_book_tile.dart';
import '../data/student_repository.dart';
import '../domain/reading_rules.dart';

/// Maximum search results shown under the search field.
const _maxResults = 20;

/// "Mulai Buku": search the shared catalog and pick a book, or type one in.
///
/// Every field stays editable after picking. Changes only apply to the
/// student's own program; the server turns them (and books that are not in
/// the catalog) into suggestions for the teachers.
class StartBookForm extends ConsumerStatefulWidget {
  const StartBookForm({super.key});

  @override
  ConsumerState<StartBookForm> createState() => _StartBookFormState();
}

class _StartBookFormState extends ConsumerState<StartBookForm> {
  final _formKey = GlobalKey<FormState>();
  final _query = TextEditingController();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _pages = TextEditingController();
  final _isbn = TextEditingController();
  final _titleFocus = FocusNode();

  /// The catalog book the form started from, if any.
  CatalogEntry? _picked;

  /// The picked book's ISBN once its full record has loaded.
  String? _pickedIsbn;

  /// The student chose to type a book that is not in the catalog.
  bool _manual = false;

  /// The student's own cover photo (cropped and compressed), if any.
  Uint8List? _coverBytes;

  @override
  void initState() {
    super.initState();
    // "Baca buku ini" on a catalog page hands the book over.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(pendingBookPickProvider);
      if (pending != null && mounted) _takePending(pending);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _title.dispose();
    _author.dispose();
    _pages.dispose();
    _isbn.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _takePending(CatalogEntry entry) {
    ref.read(pendingBookPickProvider.notifier).clear();
    _pick(entry);
  }

  void _pick(CatalogEntry entry) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _picked = entry;
      _pickedIsbn = null;
      _manual = false;
      _coverBytes = null;
      _query.clear();
      _title.text = entry.title;
      _author.text = entry.authors;
      _pages.text = entry.pageCount > 0 ? '${entry.pageCount}' : '';
      _isbn.clear();
    });
  }

  void _clearPick() => setState(() {
    _picked = null;
    _pickedIsbn = null;
    _coverBytes = null;
    for (final controller in [_title, _author, _pages, _isbn]) {
      controller.clear();
    }
  });

  void _typeOwnBook() {
    setState(() {
      _manual = true;
      _picked = null;
      _pickedIsbn = null;
      _query.clear();
    });
    _titleFocus.requestFocus();
  }

  /// Fills the ISBN once the picked book's full record arrives.
  void _onPickedBook(CatalogBook? book) {
    if (book == null || _picked?.id != book.id || _pickedIsbn != null) return;
    final isbn = book.isbn13 ?? book.isbn10 ?? '';
    setState(() {
      _pickedIsbn = isbn;
      if (_isbn.text.isEmpty) _isbn.text = isbn;
    });
  }

  /// True when the student changed something the catalog says differently.
  bool get _differsFromCatalog {
    final picked = _picked;
    if (picked == null) return false;
    return _coverBytes != null ||
        _title.text.trim() != picked.title ||
        _author.text.trim() != picked.authors ||
        _pages.text.trim() !=
            (picked.pageCount > 0 ? '${picked.pageCount}' : '') ||
        (_pickedIsbn != null && _isbn.text.trim() != _pickedIsbn);
  }

  Future<void> _chooseCover() async {
    final Uint8List? bytes;
    try {
      bytes = await pickAndCropImage(context, shape: ImageCropShape.cover);
    } on ImageCaptureException catch (error) {
      if (mounted) showSnack(context, error.message);
      return;
    }
    if (bytes == null || !mounted) return;
    if (bytes.length >= 1024 * 1024) {
      showSnack(context, 'Foto terlalu besar. Pilih foto lain.');
      return;
    }
    setState(() => _coverBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final picked = _picked;
    final cover = _coverBytes;
    final repository = ref.read(studentRepositoryProvider);
    final ok = await runWithProgress(context, () async {
      final coverUrl = cover != null
          ? await repository.uploadProgramCover(cover)
          : picked?.coverUrl;
      await repository.startBook(
        title: _title.text.trim(),
        author: _author.text.trim(),
        totalPages: int.parse(_pages.text.trim()),
        isbn: _isbn.text.trim(),
        bookId: picked?.id,
        coverUrl: coverUrl,
      );
      return true;
    });
    if (ok == true && mounted) showSnack(context, 'Selamat membaca!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final target = defaultTargetDate(ref.watch(wibClockProvider).today());

    ref.listen(pendingBookPickProvider, (_, next) {
      if (next != null) _takePending(next);
    });
    final picked = _picked;
    if (picked != null) {
      ref.listen(
        catalogBookProvider(picked.id),
        (_, next) => _onPickedBook(next.value),
      );
      // The listener above only hears changes; the record may be cached.
      final book = ref.watch(catalogBookProvider(picked.id)).value;
      if (book != null && _pickedIsbn == null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => mounted ? _onPickedBook(book) : null,
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mulai Buku', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Cari bukumu di katalog, atau isi datanya sendiri. Target '
              'selesai: ${formatDateLong(target)}.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            if (picked != null)
              _PickedBook(
                entry: picked,
                coverBytes: _coverBytes,
                onChangeCover: _chooseCover,
                onClear: _clearPick,
              )
            else if (_manual)
              _ManualHeader(
                title: _title,
                coverBytes: _coverBytes,
                onChooseCover: _chooseCover,
                onRemoveCover: () => setState(() => _coverBytes = null),
                onSearch: () => setState(() => _manual = false),
              )
            else ...[
              BookSearchField(
                fieldKey: const Key('book-search'),
                controller: _query,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _SearchResults(query: _query.text, onPick: _pick),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('book-manual'),
                  onPressed: _typeOwnBook,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Tidak ketemu? Isi data buku sendiri'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('book-title'),
              controller: _title,
              focusNode: _titleFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Judul buku'),
              validator: validateBookTitle,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('book-author'),
              controller: _author,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Penulis',
                helperText: 'Lebih dari satu penulis dipisah koma',
              ),
              validator: validateBookAuthor,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('book-pages'),
              controller: _pages,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Jumlah halaman',
                helperText: 'Tidak bisa diubah setelah buku dimulai',
              ),
              validator: validateTotalPages,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _isbn,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'ISBN (opsional)'),
              validator: validateIsbn,
              onChanged: (_) => setState(() {}),
            ),
            if (_differsFromCatalog)
              const _Note(
                key: Key('book-edited-note'),
                icon: Icons.info_outline,
                text:
                    'Perubahanmu hanya untuk bukumu dan dikirim sebagai saran '
                    'ke penanggung jawab.',
              )
            else if (picked == null &&
                (_manual || _title.text.trim().isNotEmpty))
              const _Note(
                key: Key('book-new-note'),
                icon: Icons.lightbulb_outline,
                text: 'Buku ini dikirim sebagai saran ke katalog.',
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('book-start'),
              onPressed: _submit,
              child: const Text('Mulai membaca'),
            ),
            const SizedBox(height: 8),
            Text(
              'Memulai buku butuh koneksi internet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('Belum tahu mau baca apa?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Lihat buku rekomendasi sekolah dan yang sedang ramai dibaca '
              'teman-temanmu.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('book-explore'),
              onPressed: () => context.push(Routes.studentExplore),
              icon: const Icon(Icons.travel_explore),
              label: const Text('Jelajahi katalog'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live results under the search field. With an empty query it offers the
/// school's recommendations instead.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onPick});

  final String query;
  final ValueChanged<CatalogEntry> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final index = ref.watch(catalogIndexProvider);
    final recommended = ref.watch(recommendedBookIdsProvider);
    final schoolReaders = {
      for (final MapEntry(:key, :value)
          in (ref.watch(schoolBookStatsProvider).value ?? const {}).entries)
        key: value.readers,
    };
    final trimmed = query.trim();

    return switch (index) {
      AsyncError(:final error) => _Note(
        icon: Icons.cloud_off_outlined,
        text: error == catalogNotLoaded
            ? catalogNotLoaded.userMessage
            : 'Katalog buku tidak bisa dimuat. Kamu tetap bisa mengisi data '
                  'buku sendiri.',
      ),
      AsyncData(:final value) => () {
        if (trimmed.isEmpty) {
          final picks = searchCatalog(
            value.where((entry) => recommended.contains(entry.id)).toList(),
            '',
            recommended: recommended,
            schoolReaders: schoolReaders,
            limit: 5,
          );
          if (picks.isEmpty) return const SizedBox.shrink();
          return _ResultList(
            heading: 'Rekomendasi sekolah',
            entries: picks,
            recommended: recommended,
            schoolReaders: schoolReaders,
            onPick: onPick,
          );
        }
        final results = searchCatalog(
          value,
          trimmed,
          recommended: recommended,
          schoolReaders: schoolReaders,
          limit: _maxResults,
        );
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              value.isEmpty
                  ? 'Katalog buku masih kosong.'
                  : 'Tidak ada buku yang cocok dengan "$trimmed".',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          );
        }
        return _ResultList(
          entries: results,
          recommended: recommended,
          schoolReaders: schoolReaders,
          onPick: onPick,
        );
      }(),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    this.heading,
    required this.entries,
    required this.recommended,
    required this.schoolReaders,
    required this.onPick,
  });

  final String? heading;
  final List<CatalogEntry> entries;
  final List<String> recommended;
  final Map<String, int> schoolReaders;
  final ValueChanged<CatalogEntry> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (heading != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                child: Text(heading!, style: theme.textTheme.labelLarge),
              ),
            for (final (position, entry) in entries.indexed)
              CatalogBookTile(
                key: Key('book-search-result-$position'),
                entry: entry,
                recommended: recommended.contains(entry.id),
                schoolReaders: schoolReaders[entry.id] ?? 0,
                onTap: () => onPick(entry),
                trailing: Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The catalog book the form started from, with "Ganti buku" and the option
/// to use the student's own cover photo.
class _PickedBook extends StatelessWidget {
  const _PickedBook({
    required this.entry,
    required this.coverBytes,
    required this.onChangeCover,
    required this.onClear,
  });

  final CatalogEntry entry;
  final Uint8List? coverBytes;
  final VoidCallback onChangeCover;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverButton(
              title: entry.title,
              coverUrl: entry.coverUrl,
              bytes: coverBytes,
              onTap: onChangeCover,
              tooltip: 'Ganti cover untuk bukumu',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dari katalog',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    entry.authors,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        key: const Key('book-clear-pick'),
                        onPressed: onClear,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Ganti buku'),
                      ),
                      TextButton.icon(
                        key: const Key('book-change-cover'),
                        onPressed: onChangeCover,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Foto cover'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header of the manual form: back to search, and an optional cover photo.
class _ManualHeader extends StatelessWidget {
  const _ManualHeader({
    required this.title,
    required this.coverBytes,
    required this.onChooseCover,
    required this.onRemoveCover,
    required this.onSearch,
  });

  final TextEditingController title;
  final Uint8List? coverBytes;
  final VoidCallback onChooseCover;
  final VoidCallback onRemoveCover;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('book-back-to-search'),
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Text('Cari di katalog'),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: title,
              builder: (_, value, _) => _CoverButton(
                title: value.text.trim().isEmpty ? 'Buku' : value.text,
                bytes: coverBytes,
                onTap: onChooseCover,
                tooltip: 'Foto cover',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Foto cover', style: theme.textTheme.titleSmall),
                  Text(
                    'Opsional. Foto sampul depan bukumu supaya mudah dikenali.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        key: const Key('book-cover-photo'),
                        onPressed: onChooseCover,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(
                          coverBytes == null ? 'Tambah foto' : 'Ganti foto',
                        ),
                      ),
                      if (coverBytes != null)
                        TextButton(
                          key: const Key('book-cover-remove'),
                          onPressed: onRemoveCover,
                          child: const Text('Hapus'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A cover that opens the photo picker when tapped, with a small camera
/// badge. Shows the student's own photo when one was chosen.
class _CoverButton extends StatelessWidget {
  const _CoverButton({
    required this.title,
    required this.bytes,
    required this.onTap,
    required this.tooltip,
    this.coverUrl,
  });

  static const _width = 72.0;

  final String title;
  final String? coverUrl;
  final Uint8List? bytes;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(_width * 0.14);
    final own = bytes;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (own != null)
              ClipRRect(
                borderRadius: radius,
                child: Image.memory(
                  own,
                  width: _width,
                  height: _width * 1.5,
                  fit: BoxFit.cover,
                ),
              )
            else
              BookCover(title: title, coverUrl: coverUrl, width: _width),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: 14,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.infoTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: palette.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.info),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
