import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../errors/app_exception.dart';
import '../models/report.dart';

const reportSentMessage =
    'Laporan terkirim. Penanggung jawab sekolah dan pengembang akan '
    'meninjaunya.';

/// For a report about a penanggung jawab, which only the developer reads.
const reportSentToDeveloperMessage =
    'Laporan terkirim. Pengembang Sabu Saku akan meninjaunya.';

/// Asks why [target] is reported, with an optional note, and sends it.
/// Confirms with a SnackBar once the report is in.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReportTarget target,
}) async {
  final repository = ref.read(reportRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => ReportSheet(
      kind: target.kind,
      developerOnly: target.developerOnly,
      onSubmit: (reason, note) =>
          repository.report(target, reason: reason, note: note),
    ),
  );
  if (sent ?? false) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            target.developerOnly
                ? reportSentToDeveloperMessage
                : reportSentMessage,
          ),
        ),
      );
  }
}

/// The content of the report sheet. Pops `true` once [onSubmit] succeeded.
class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.kind,
    required this.onSubmit,
    this.developerOnly = false,
  });

  final ReportKind kind;

  /// The report is about a penanggung jawab and goes to the developer only.
  final bool developerOnly;
  final Future<void> Function(ReportReason reason, String? note) onSubmit;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _note = TextEditingController();
  ReportReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      await widget.onSubmit(reason, note.isEmpty ? null : note);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapError(error).userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: const Key('report-sheet'),
      // Keeps the note field and the button above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Laporkan ${widget.kind.noun}',
                style: theme.textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.developerOnly
                    ? 'Apa masalahnya? Laporan tentang penanggung jawab hanya '
                          'dibaca pengembang Sabu Saku.'
                    : 'Apa masalahnya? Laporanmu ditinjau penanggung jawab '
                          'sekolah dan pengembang Sabu Saku.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) {
                if (_busy) return;
                setState(() => _reason = value);
              },
              child: Column(
                children: [
                  for (final reason in ReportReason.forKind(widget.kind))
                    RadioListTile<ReportReason>(
                      key: Key('report-reason-${reason.wire}'),
                      value: reason,
                      title: Text(reason.label),
                      dense: true,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                key: const Key('report-note'),
                controller: _note,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                maxLength: maxReportNoteLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Ceritakan singkat apa yang salah',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FilledButton(
                key: const Key('report-submit'),
                onPressed: _reason == null || _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Kirim laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
