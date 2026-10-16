import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/data/reading_repository.dart';
import '../../../core/models/journal.dart';
import '../../../core/models/program.dart';
import '../../../core/time/date_format.dart';
import '../../../core/time/wib_clock.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../data/journal_outbox.dart';
import '../data/student_repository.dart';
import '../domain/journal_draft.dart';
import '../domain/reading_rules.dart';

/// "Isi Jurnal": write the journal for today or up to two days back, or edit
/// one that is still inside its edit window.
class JournalFormScreen extends ConsumerStatefulWidget {
  const JournalFormScreen({super.key, this.initialDate});

  /// Preselected date; defaults to today.
  final String? initialDate;

  @override
  ConsumerState<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends ConsumerState<JournalFormScreen> {
  String? _date;

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(activeProgramProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Isi Jurnal')),
      body: AsyncView<Program?>(
        value: program,
        data: (active) {
          if (active == null) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Belum ada buku',
              message: 'Mulai satu buku dulu sebelum mengisi jurnal.',
              action: FilledButton(
                onPressed: () => context.go(Routes.studentBook),
                child: const Text('Mulai Buku'),
              ),
            );
          }
          final today = ref.watch(wibClockProvider).today();
          final choices = journalDateChoices(
            today: today,
            programStartDate: active.startDate,
          );
          final date = choices.contains(_date ?? widget.initialDate)
              ? (_date ?? widget.initialDate)!
              : choices.first;
          return _DateScope(
            program: active,
            today: today,
            choices: choices,
            date: date,
            onDateChanged: (value) => setState(() => _date = value),
          );
        },
      ),
    );
  }
}

/// Loads the journal of the selected date, if any, before showing the form.
class _DateScope extends ConsumerWidget {
  const _DateScope({
    required this.program,
    required this.today,
    required this.choices,
    required this.date,
    required this.onDateChanged,
  });

  final Program program;
  final String today;
  final List<String> choices;
  final String date;
  final ValueChanged<String> onDateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(journalProvider(program.id, date));
    // The server's "last page" lags while offline; journals in the local
    // cache know better.
    final recent =
        ref.watch(journalsProvider(program.id, 5)).value ?? const <Journal>[];
    final lastPage = recent.fold(
      program.currentPage,
      (max, journal) => journal.pageEnd > max ? journal.pageEnd : max,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                for (final choice in choices)
                  ButtonSegment(
                    value: choice,
                    label: Text(formatRelativeDay(choice, today)),
                  ),
              ],
              selected: {date},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onDateChanged(selection.first),
            ),
          ),
        ),
        Expanded(
          child: AsyncView<Journal?>(
            value: existing,
            data: (journal) => _JournalForm(
              // A fresh form per date and per loaded journal.
              key: ValueKey('$date-${journal != null}'),
              program: program,
              date: date,
              today: today,
              existing: journal,
              lastPage: lastPage,
            ),
          ),
        ),
      ],
    );
  }
}

class _JournalForm extends ConsumerStatefulWidget {
  const _JournalForm({
    super.key,
    required this.program,
    required this.date,
    required this.today,
    required this.existing,
    required this.lastPage,
  });

  final Program program;
  final String date;
  final String today;
  final Journal? existing;
  final int lastPage;

  @override
  ConsumerState<_JournalForm> createState() => _JournalFormState();
}

class _JournalFormState extends ConsumerState<_JournalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pageStart;
  late final TextEditingController _pageEnd;
  late final TextEditingController _keyInformation;
  late final TextEditingController _reflection;
  late final TextEditingController _question;
  DurationRange? _duration;
  bool _durationMissing = false;

  int get _totalPages => widget.program.book.totalPages;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _pageStart = TextEditingController(
      text:
          '${existing?.pageStart ?? defaultPageStart(currentPage: widget.lastPage, totalPages: _totalPages)}',
    );
    _pageEnd = TextEditingController(text: existing?.pageEnd.toString() ?? '');
    _keyInformation = TextEditingController(text: existing?.keyInformation);
    _reflection = TextEditingController(text: existing?.reflection);
    _question = TextEditingController(text: existing?.question);
    _duration = existing?.durationRange;
    _keyInformation.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _pageStart.dispose();
    _pageEnd.dispose();
    _keyInformation.dispose();
    _reflection.dispose();
    _question.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    setState(() => _durationMissing = _duration == null);
    if (!valid || _duration == null) return;

    ref
        .read(journalWriterProvider)
        .save(
          programId: widget.program.id,
          bookTitle: widget.program.book.title,
          isNew: widget.existing == null,
          draft: JournalDraft(
            date: widget.date,
            pageStart: int.parse(_pageStart.text.trim()),
            pageEnd: int.parse(_pageEnd.text.trim()),
            durationRange: _duration!,
            keyInformation: _keyInformation.text,
            reflection: _reflection.text,
            question: _question.text,
          ),
        );
    // The write is queued locally at once and syncs on its own, so the
    // screen does not wait for the network.
    showSnack(context, 'Jurnal tersimpan');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;

    if (existing != null &&
        !canEditJournal(journalDate: widget.date, today: widget.today)) {
      return EmptyState(
        icon: Icons.lock_outline,
        title: 'Jurnal tanggal ini sudah terkunci',
        message: 'Jurnal hanya bisa diubah sampai sehari setelah tanggalnya.',
        action: OutlinedButton(
          onPressed: () => context.pushReplacement(
            Routes.studentJournal(widget.program.id, widget.date),
          ),
          child: const Text('Lihat jurnal'),
        ),
      );
    }

    final keyLength = _keyInformation.text.trim().length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              formatDateLong(widget.date),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              existing == null
                  ? widget.program.book.title
                  : '${widget.program.book.title} · mengubah jurnal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('journal-page-start'),
                    controller: _pageStart,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Dari halaman',
                    ),
                    validator: validatePageStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('journal-page-end'),
                    controller: _pageEnd,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Sampai halaman',
                      helperText: 'Maks. $_totalPages',
                    ),
                    validator: (value) => validatePageEnd(
                      value,
                      pageStartInput: _pageStart.text,
                      totalPages: _totalPages,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Durasi membaca', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final range in DurationRange.values)
                  ChoiceChip(
                    key: Key('journal-duration-${range.wire}'),
                    label: Text(range.label),
                    selected: _duration == range,
                    onSelected: (_) => setState(() {
                      _duration = range;
                      _durationMissing = false;
                    }),
                  ),
              ],
            ),
            if (_durationMissing)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Pilih durasi membaca',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('journal-key-information'),
              controller: _keyInformation,
              minLines: 4,
              maxLines: 10,
              maxLength: journalTextMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Informasi penting (wajib)',
                hintText: 'Apa isi bacaanmu hari ini?',
                alignLabelWithHint: true,
                counterText: keyLength < keyInformationMinLength
                    ? '$keyLength/$keyInformationMinLength minimal'
                    : '$keyLength/$journalTextMaxLength',
              ),
              validator: validateKeyInformation,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('journal-reflection'),
              controller: _reflection,
              minLines: 2,
              maxLines: 8,
              maxLength: journalTextMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Hal yang menarik (opsional)',
                alignLabelWithHint: true,
              ),
              validator: validateOptionalText,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('journal-question'),
              controller: _question,
              minLines: 2,
              maxLines: 8,
              maxLength: journalTextMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan (opsional)',
                alignLabelWithHint: true,
              ),
              validator: validateOptionalText,
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('journal-save'),
              onPressed: _submit,
              child: Text(existing == null ? 'Simpan' : 'Simpan perubahan'),
            ),
            const SizedBox(height: 8),
            Text(
              'Bisa disimpan tanpa sinyal. Jurnal dikirim saat online.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
