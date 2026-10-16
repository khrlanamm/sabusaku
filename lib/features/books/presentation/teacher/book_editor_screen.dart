import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/image_capture.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/states.dart';
import '../../data/book_admin_repository.dart';
import '../../domain/book_categories.dart';
import '../../domain/catalog_book.dart';

/// Values that open the editor for a student's "new book" suggestion.
class BookEditorSeed {
  const BookEditorSeed({
    required this.suggestionId,
    this.fields = const {},
    this.coverUrl,
  });

  final String suggestionId;

  /// Proposed values keyed like `books` fields.
  final Map<String, Object?> fields;

  /// The cover the student photographed; the server copies it on create.
  final String? coverUrl;
}

/// Creates a book, edits one ([bookId]), or turns a student's suggestion
/// into a catalog book ([seed]).
class BookEditorScreen extends ConsumerWidget {
  const BookEditorScreen({super.key, this.bookId, this.seed});

  final String? bookId;
  final BookEditorSeed? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = bookId;
    if (id == null) return _BookEditor(seed: seed);
    final book = ref.watch(adminBookProvider(id));
    return AsyncView<CatalogBook?>(
      value: book,
      loading: Scaffold(
        appBar: AppBar(title: const Text('Ubah buku')),
        body: const SkeletonList(),
      ),
      data: (book) => book == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Ubah buku')),
              body: const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Buku tidak ditemukan',
              ),
            )
          : _BookEditor(book: book),
    );
  }
}

class _BookEditor extends ConsumerStatefulWidget {
  const _BookEditor({this.book, this.seed});

  final CatalogBook? book;
  final BookEditorSeed? seed;

  @override
  ConsumerState<_BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends ConsumerState<_BookEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _authors;
  late final TextEditingController _publisher;
  late final TextEditingController _year;
  late final TextEditingController _isbn13;
  late final TextEditingController _isbn10;
  late final TextEditingController _pages;
  late final TextEditingController _description;
  late Set<String> _categories;
  Uint8List? _cover;
  bool _busy = false;

  bool get _editing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    final seed = widget.seed?.fields ?? const <String, Object?>{};
    String text(String field, Object? fromBook) {
      final value = fromBook ?? seed[field];
      return switch (value) {
        null => '',
        final List<Object?> list => list.whereType<Object>().join(', '),
        final Object other => other.toString(),
      };
    }

    _title = TextEditingController(text: text('title', book?.title));
    _subtitle = TextEditingController(text: text('subtitle', book?.subtitle));
    _authors = TextEditingController(text: text('authors', book?.authors));
    _publisher = TextEditingController(
      text: text('publisher', book?.publisher),
    );
    _year = TextEditingController(
      text: text('publishedYear', book?.publishedYear),
    );
    _isbn13 = TextEditingController(text: text('isbn13', book?.isbn13));
    _isbn10 = TextEditingController(text: text('isbn10', book?.isbn10));
    _pages = TextEditingController(text: text('pageCount', book?.pageCount));
    _description = TextEditingController(
      text: text('description', book?.description),
    );
    _categories = {
      ...?book?.categories,
      if (book == null)
        ...List<String>.from(seed['categories'] as List? ?? const [])
            .where(bookCategories.contains),
    };
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _subtitle,
      _authors,
      _publisher,
      _year,
      _isbn13,
      _isbn10,
      _pages,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static List<String> _splitAuthors(String raw) => [
    for (final part in raw.split(RegExp(r'[,;]')))
      if (part.trim().isNotEmpty) part.trim().replaceAll(RegExp(r'\s+'), ' '),
  ];

  static String _digits(String raw) =>
      raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  static String? _optional(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _fields() => {
    'title': _title.text.trim(),
    'subtitle': _optional(_subtitle),
    'authors': _splitAuthors(_authors.text),
    'publisher': _optional(_publisher),
    'publishedYear': int.tryParse(_year.text.trim()),
    'isbn13': _digits(_isbn13.text).isEmpty ? null : _digits(_isbn13.text),
    'isbn10': _digits(_isbn10.text).isEmpty ? null : _digits(_isbn10.text),
    'pageCount': int.parse(_pages.text.trim()),
    'categories': [
      for (final category in bookCategories)
        if (_categories.contains(category)) category,
    ],
    'description': _optional(_description),
  };

  Future<void> _pickCover() async {
    final bytes = await pickAndCropImage(context, shape: ImageCropShape.cover);
    if (bytes != null && mounted) setState(() => _cover = bytes);
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_categories.isEmpty) {
      showSnack(context, 'Pilih minimal satu kategori.');
      return;
    }
    setState(() => _busy = true);
    final repository = ref.read(bookAdminRepositoryProvider);
    try {
      final fields = _fields();
      final seed = widget.seed;
      final String id;
      if (seed != null) {
        id = await repository.createFromSuggestion(seed.suggestionId, fields);
      } else {
        id = await repository.saveBook(bookId: widget.book?.id, fields: fields);
      }
      final cover = _cover;
      if (cover != null) await repository.uploadCover(id, cover);
      if (!mounted) return;
      showSnack(
        context,
        _editing ? 'Perubahan disimpan.' : 'Buku ditambahkan ke katalog.',
      );
      if (_editing) {
        context.pop();
      } else {
        context.pushReplacement(Routes.teacherBook(id));
      }
    } on BookExistsException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      final open = await showConfirmDialog(
        context,
        title: 'Buku ini sudah ada',
        message: '${error.message}\n\nBuka buku yang sudah ada?',
        confirmLabel: 'Buka',
      );
      if (open && mounted) context.push(Routes.teacherBook(error.bookId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, mapError(error).userMessage);
    }
  }

  String? _required(String? value, {int min = 2, int max = 200}) {
    final text = value?.trim() ?? '';
    if (text.length < min) return 'Minimal $min karakter';
    if (text.length > max) return 'Maksimal $max karakter';
    return null;
  }

  String? _optionalMax(String? value, int max) =>
      (value?.trim().length ?? 0) > max ? 'Maksimal $max karakter' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seed = widget.seed;
    final title = _editing
        ? 'Ubah buku'
        : seed != null
        ? 'Tambahkan saran ke katalog'
        : 'Tambah buku';
    final existingCover = widget.book?.coverUrl ?? seed?.coverUrl;
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (seed != null) ...[
              Text(
                'Data diisi dari saran siswa. Periksa dan rapikan sebelum '
                'menyimpan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Center(
              child: Column(
                children: [
                  _cover != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _cover!,
                            width: 96,
                            height: 144,
                            fit: BoxFit.cover,
                          ),
                        )
                      : BookCover(
                          title: _title.text.isEmpty ? 'Buku' : _title.text,
                          width: 96,
                          coverUrl: existingCover,
                        ),
                  TextButton.icon(
                    key: const Key('editor-cover'),
                    onPressed: _busy ? null : _pickCover,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      _cover == null && existingCover == null
                          ? 'Tambah cover'
                          : 'Ganti cover',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('editor-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Judul'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => _required(v),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitle,
              decoration: const InputDecoration(
                labelText: 'Subjudul (opsional)',
              ),
              validator: (v) => _optionalMax(v, 200),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('editor-authors'),
              controller: _authors,
              decoration: const InputDecoration(
                labelText: 'Penulis',
                helperText: 'Lebih dari satu? Pisahkan dengan koma',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                final authors = _splitAuthors(value ?? '');
                if (authors.isEmpty) return 'Isi nama penulis';
                if (authors.length > 5) return 'Maksimal 5 penulis';
                if (authors.any((a) => a.length < 2 || a.length > 120)) {
                  return 'Nama penulis 2–120 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publisher,
              decoration: const InputDecoration(
                labelText: 'Penerbit (opsional)',
              ),
              validator: (v) => _optionalMax(v, 120),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('editor-pages'),
                    controller: _pages,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah halaman',
                    ),
                    validator: (value) {
                      final pages = int.tryParse(value?.trim() ?? '');
                      if (pages == null || pages < 10 || pages > 2000) {
                        return '10–2000 halaman';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    decoration: const InputDecoration(
                      labelText: 'Tahun terbit',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final year = int.tryParse(text);
                      if (year == null || year < 1800 || year > 2100) {
                        return 'Tahun tidak valid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn13,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ISBN-13 (opsional)',
                hintText: '978…',
              ),
              validator: (value) {
                final digits = _digits(value ?? '');
                if (digits.isEmpty) return null;
                return RegExp(r'^\d{13}$').hasMatch(digits)
                    ? null
                    : 'ISBN-13 terdiri dari 13 angka';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn10,
              decoration: const InputDecoration(
                labelText: 'ISBN-10 (opsional)',
              ),
              validator: (value) {
                final digits = _digits(value ?? '');
                if (digits.isEmpty) return null;
                return RegExp(r'^\d{9}[\dX]$').hasMatch(digits)
                    ? null
                    : 'ISBN-10 terdiri dari 10 karakter';
              },
            ),
            const SizedBox(height: 20),
            Text('Kategori', style: theme.textTheme.titleSmall),
            Text(
              'Pilih 1 sampai 3',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in bookCategories)
                  FilterChip(
                    key: Key('editor-category-$category'),
                    label: Text(category),
                    selected: _categories.contains(category),
                    onSelected:
                        !_categories.contains(category) &&
                            _categories.length >= 3
                        ? null
                        : (selected) => setState(
                            () => selected
                                ? _categories.add(category)
                                : _categories.remove(category),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 10,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Sinopsis (opsional)',
                alignLabelWithHint: true,
              ),
              validator: (v) => _optionalMax(v, 2000),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('editor-save'),
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      _editing
                          ? 'Simpan perubahan'
                          : seed != null
                          ? 'Tambahkan ke katalog'
                          : 'Simpan buku',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
