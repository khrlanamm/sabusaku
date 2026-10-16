import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/palette.dart';
import '../../../core/data/report_repository.dart';
import '../../../core/models/report.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/states.dart';
import '../../auth/domain/app_user.dart';
import '../../books/presentation/teacher/book_format.dart' show relativeTime;

/// Reports from this school's users, for its penanggung jawab: what was
/// reported and why, by whom, and a way to the content. "Tandai selesai"
/// records what was done.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(schoolReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Terbuka', key: Key('reports-open')),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Selesai', key: Key('reports-resolved')),
                  ),
                ],
                selected: {_showResolved},
                onSelectionChanged: (value) =>
                    setState(() => _showResolved = value.single),
              ),
            ),
          ),
          Expanded(
            child: AsyncView<List<Report>>(
              value: reports,
              onRetry: () => ref.invalidate(schoolReportsProvider),
              data: (all) {
                final shown = [
                  for (final report in all)
                    if (report.resolved == _showResolved) report,
                ];
                if (shown.isEmpty) {
                  return _showResolved
                      ? const EmptyState(
                          icon: Icons.task_alt,
                          title: 'Belum ada laporan selesai',
                        )
                      : const EmptyState(
                          icon: Icons.verified_outlined,
                          title: 'Tidak ada laporan terbuka',
                          message:
                              'Laporan muncul di sini saat siswa atau '
                              'penanggung jawab melaporkan komentar, jurnal, '
                              'buku, atau pengguna.',
                        );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReportCard(report: shown[i], index: i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One report: kind and reason, the reported content as it was, the note,
/// who reported it and when, and the actions.
class ReportCard extends ConsumerWidget {
  const ReportCard({super.key, required this.report, required this.index});

  final Report report;

  /// Position in the list, for the keys.
  final int index;

  /// Where "Buka" leads, or null when the content cannot be opened. Reports
  /// about a penanggung jawab (comments, their accounts) never reach this
  /// list: only the developer reads them.
  String? get _location {
    if (report.targetDeleted) return null;
    final target = report.target;
    return switch (report.kind) {
      ReportKind.book when target.bookId != null => Routes.teacherBook(
        target.bookId!,
      ),
      ReportKind.suggestion when target.suggestionId != null =>
        Routes.teacherSuggestion(target.suggestionId!),
      // The subject of a journal report is the student.
      ReportKind.journal
          when report.subjectId != null &&
              target.programId != null &&
              target.date != null =>
        Routes.teacherJournal(
          report.subjectId!,
          target.programId!,
          target.date!,
        ),
      // Only students have a detail screen.
      ReportKind.user
          when target.userId != null &&
              UserRole.fromWire(report.snapshot['role']) == UserRole.siswa =>
        Routes.teacherStudent(target.userId!),
      _ => null,
    };
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final resolution = await showDialog<String>(
      context: context,
      builder: (_) => const _ResolveDialog(),
    );
    if (resolution == null || !context.mounted) return;
    final ok = await runWithProgress(context, () async {
      await ref
          .read(reportRepositoryProvider)
          .resolve(report.id, resolution: resolution);
      return true;
    });
    if (ok == true && context.mounted) {
      showSnack(context, 'Laporan ditandai selesai.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = context.palette;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final reporter = [
      report.reporterName.isEmpty ? 'Pengguna' : report.reporterName,
      if (report.reporterRole != null) '(${report.reporterRole!.label})',
    ].join(' ');

    return Card(
      key: Key('report-card-$index'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _KindPill(kind: report.kind),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.reason.label,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Snapshot(report: report),
            if (report.note != null) ...[
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Catatan pelapor: ',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    TextSpan(text: report.note),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Dilaporkan oleh $reporter · ${relativeTime(report.createdAt)}',
              style: muted,
            ),
            if (report.resolved) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.activeTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.task_alt, size: 18, color: palette.activeText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selesai oleh ${report.resolvedByName ?? 'penanggung jawab'}'
                            '${report.resolvedAt == null ? '' : ' · ${relativeTime(report.resolvedAt)}'}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: palette.activeText,
                            ),
                          ),
                          if (report.resolution != null)
                            Text(
                              report.resolution!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: palette.activeText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                if (_location case final location?)
                  TextButton.icon(
                    key: Key('report-open-$index'),
                    onPressed: () => context.push(location),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Buka'),
                  ),
                if (!report.resolved)
                  FilledButton.tonalIcon(
                    key: Key('report-resolve-$index'),
                    onPressed: () => _resolve(context, ref),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Tandai selesai'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.kind});

  final ReportKind kind;

  static const _icons = {
    ReportKind.comment: Icons.chat_bubble_outline,
    ReportKind.journal: Icons.edit_note,
    ReportKind.book: Icons.menu_book_outlined,
    ReportKind.suggestion: Icons.lightbulb_outline,
    ReportKind.user: Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.attentionTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[kind], size: 15, color: palette.attentionText),
          const SizedBox(width: 5),
          Text(
            kind.label,
            style: TextStyle(
              color: palette.attentionText,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The reported content as copied at report time.
class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final muted = theme.colorScheme.onSurfaceVariant;
    final heading = theme.textTheme.labelLarge?.copyWith(
      color: palette.heading,
    );
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.4);
    String? text(String key) => report.snapshotText(key);

    final Widget content;
    if (report.targetDeleted || report.snapshot.isEmpty) {
      content = Text(
        'Konten sudah dihapus.',
        style: body?.copyWith(color: muted, fontStyle: FontStyle.italic),
      );
    } else {
      content = switch (report.kind) {
        ReportKind.comment => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text('authorName') ?? 'Penanggung jawab', style: heading),
            const SizedBox(height: 2),
            Text(
              text('text') ?? '',
              style: body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        ReportKind.journal => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                text('studentName') ?? 'Siswa',
                if (text('date') case final date?) _dateLabel(date),
              ].join(' · '),
              style: heading,
            ),
            const SizedBox(height: 2),
            Text(
              text('keyInformation') ?? '',
              style: body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        ReportKind.book || ReportKind.suggestion => Row(
          children: [
            BookCover(
              title: text('title') ?? '?',
              coverUrl: text('coverUrl'),
              width: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text('title') ?? 'Tanpa judul', style: heading),
                  if (_authors(report.snapshot['authors']) case final authors?)
                    Text(authors, style: body?.copyWith(color: muted)),
                ],
              ),
            ),
          ],
        ),
        ReportKind.user => Row(
          children: [
            Icon(Icons.account_circle_outlined, color: palette.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [
                  text('name') ?? 'Pengguna',
                  if (UserRole.fromWire(report.snapshot['role'])
                      case final role?)
                    role.label,
                ].join(' · '),
                style: heading,
              ),
            ),
          ],
        ),
      };
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.neutralTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  static String _dateLabel(String date) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)
      ? formatDateShort(date)
      : date;

  static String? _authors(Object? value) {
    final text = switch (value) {
      final List<Object?> list => list.whereType<String>().join(', '),
      final String s => s,
      _ => '',
    }.trim();
    return text.isEmpty ? null : text;
  }
}

/// Asks what was done about the report. Pops the note ('' for none), or
/// null when cancelled.
class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog();

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tandai selesai?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tulis tindakan yang sudah diambil, misalnya "komentar sudah '
            'dihapus". Boleh dikosongkan.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('report-resolution'),
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            maxLength: maxReportNoteLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tindakan (opsional)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('report-resolve-confirm'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Tandai selesai'),
        ),
      ],
    );
  }
}
