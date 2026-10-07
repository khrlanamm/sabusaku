import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../data/student_repository.dart';
import '../domain/reading_rules.dart';
import 'student_home_screen.dart';

/// "Buku Saya": the active book, or the form to start one.
class BookScreen extends ConsumerWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(activeProgramProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Buku Saya')),
      body: AsyncView<Program?>(
        value: program,
        onRetry: () => ref.invalidate(activeProgramProvider),
        data: (active) => active == null
            ? const _StartBookForm()
            : _ActiveBook(program: active),
      ),
    );
  }
}

class _StartBookForm extends ConsumerStatefulWidget {
  const _StartBookForm();

  @override
  ConsumerState<_StartBookForm> createState() => _StartBookFormState();
}

class _StartBookFormState extends ConsumerState<_StartBookForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _pages = TextEditingController();
  final _isbn = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _pages.dispose();
    _isbn.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await runWithProgress(context, () async {
      await ref
          .read(studentRepositoryProvider)
          .startBook(
            title: _title.text.trim(),
            author: _author.text.trim(),
            totalPages: int.parse(_pages.text.trim()),
            isbn: _isbn.text.trim(),
          );
      return true;
    });
    if (ok == true && mounted) showSnack(context, 'Selamat membaca!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = defaultTargetDate(ref.watch(wibClockProvider).today());
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
              'Pilih buku apa saja. Target selesai: '
              '${formatDateLong(target)}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('book-title'),
              controller: _title,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Judul buku'),
              validator: validateBookTitle,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('book-author'),
              controller: _author,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Penulis'),
              validator: validateBookAuthor,
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
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _isbn,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'ISBN (opsional)'),
              validator: validateIsbn,
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBook extends ConsumerWidget {
  const _ActiveBook({required this.program});

  final Program program;

  Future<void> _extend(BuildContext context, WidgetRef ref) async {
    final newTarget = extendedTargetDate(program.targetDate);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Perpanjang target?',
      message:
          'Target selesai menjadi ${formatDateLong(newTarget)}. '
          'Perpanjangan hanya bisa satu kali.',
      confirmLabel: 'Perpanjang',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(studentRepositoryProvider).extendTarget(program);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Target diperpanjang');
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final reflection = await showDialog<String>(
      context: context,
      builder: (_) => const _FinalReflectionDialog(),
    );
    if (reflection == null || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(studentRepositoryProvider)
          .completeBook(program, finalReflection: reflection.trim());
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Selamat, satu buku selesai!');
    }
  }

  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hentikan buku ini?',
      message:
          'Buku dan jurnalnya tetap tersimpan di riwayat, tetapi tidak bisa '
          'dilanjutkan. Kamu bisa memulai buku baru.',
      confirmLabel: 'Hentikan',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref.read(studentRepositoryProvider).stopBook(program);
      return true;
    });
    if (ok == true && context.mounted) showSnack(context, 'Buku dihentikan');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(wibClockProvider).today();
    final overdue = program.isOverdue(today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(title: program.book.title, width: 96),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program.book.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    program.book.author,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  if (overdue)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: OverdueLabel(),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Progres', style: theme.textTheme.titleSmall),
                    ),
                    Text(
                      '${program.percent}%',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(percent: program.percent, height: 10),
                const SizedBox(height: 6),
                Text(
                  'Halaman ${program.currentPage} dari '
                  '${program.book.totalPages}',
                  style: theme.textTheme.bodySmall,
                ),
                const Divider(height: 28),
                _Fact(label: 'Mulai', value: formatDateLong(program.startDate)),
                _Fact(
                  label: 'Target selesai',
                  value:
                      formatDateLong(program.targetDate) +
                      (program.extended ? ' (diperpanjang)' : ''),
                ),
                _Fact(label: 'Jurnal', value: '${program.journalCount} hari'),
                if (program.book.isbn != null)
                  _Fact(label: 'ISBN', value: program.book.isbn!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('book-complete'),
          onPressed: program.isFullyRead ? () => _complete(context, ref) : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Tandai Selesai'),
        ),
        if (!program.isFullyRead)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tersedia setelah jurnalmu mencapai halaman terakhir.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (!program.extended)
          OutlinedButton.icon(
            key: const Key('book-extend'),
            onPressed: () => _extend(context, ref),
            icon: const Icon(Icons.event_repeat),
            label: const Text('Perpanjang target'),
          ),
        const SizedBox(height: 4),
        TextButton.icon(
          key: const Key('book-stop'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => _stop(context, ref),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Hentikan buku'),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
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
    );
  }
}

/// Optional closing review when a book is marked finished (PRD BR-10).
/// Pops the text (possibly empty) to confirm, or null when cancelled.
class _FinalReflectionDialog extends StatefulWidget {
  const _FinalReflectionDialog();

  @override
  State<_FinalReflectionDialog> createState() => _FinalReflectionDialogState();
}

class _FinalReflectionDialogState extends State<_FinalReflectionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buku selesai dibaca'),
      content: TextField(
        key: const Key('book-final-reflection'),
        controller: _controller,
        maxLines: 5,
        maxLength: journalTextMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Ulasan akhir (opsional)',
          hintText: 'Apa kesanmu tentang buku ini?',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('book-complete-confirm'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Tandai selesai'),
        ),
      ],
    );
  }
}
