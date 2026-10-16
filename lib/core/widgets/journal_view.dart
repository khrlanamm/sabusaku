import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/palette.dart';
import '../../features/auth/data/auth_repository.dart';
import '../models/journal.dart';
import '../models/report.dart';
import '../time/date_format.dart';
import 'report_sheet.dart';

/// The content of one journal, shared by the student and teacher views.
class JournalContentView extends StatelessWidget {
  const JournalContentView({super.key, required this.journal});

  final Journal journal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(formatDateLong(journal.date), style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Icons.menu_book_outlined,
              label:
                  'Hal. ${journal.pageStart}–${journal.pageEnd} '
                  '(${journal.pagesRead} hal.)',
            ),
            _Pill(icon: Icons.schedule, label: journal.durationRange.label),
            if (journal.pendingSync)
              _Pill(
                icon: Icons.cloud_upload_outlined,
                label: 'Menunggu sinkron',
                color: context.palette.attentionText,
                tint: context.palette.attentionTint,
              ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(title: 'Informasi penting', text: journal.keyInformation),
        if (journal.reflection != null)
          _Section(title: 'Hal yang menarik', text: journal.reflection!),
        if (journal.question != null)
          _Section(title: 'Pertanyaan', text: journal.question!),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.color, this.tint});

  final IconData icon;
  final String label;

  /// Heading colour on the info tint when null.
  final Color? color;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.palette.heading;
    final tint = this.tint ?? context.palette.infoTint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a journal list.
class JournalListTile extends StatelessWidget {
  const JournalListTile({
    super.key,
    required this.journal,
    required this.onTap,
    this.showUnreadBadge = true,
  });

  final Journal journal;
  final VoidCallback onTap;

  /// Teachers do not see the student's "unread comment" marker.
  final bool showUnreadBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDateLong(journal.date),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (journal.pendingSync)
                    Tooltip(
                      message: 'Menunggu sinkron',
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 18,
                        color: context.palette.attentionText,
                      ),
                    ),
                  if (showUnreadBadge && journal.hasUnreadTeacherComment)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: _CommentBadge(),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Hal. ${journal.pageStart}–${journal.pageEnd} · '
                '${journal.durationRange.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                journal.keyInformation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentBadge extends StatelessWidget {
  const _CommentBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble, size: 12, color: scheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            'Komentar baru',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A teacher's comment bubble. [actions] is shown to the author only; any
/// other reader gets a menu to report the comment or its author when the
/// journal ([programId], [date]) is given.
class CommentTile extends ConsumerWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.actions,
    this.programId,
    this.date,
  });

  final JournalComment comment;
  final Widget? actions;
  final String? programId;
  final String? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentSessionProvider.select((s) => s.uid));
    final programId = this.programId;
    final date = this.date;
    final reportMenu =
        programId == null || date == null || comment.teacherId == myUid
        ? null
        : PopupMenuButton<ReportTarget>(
            key: const Key('comment-menu'),
            tooltip: 'Laporkan',
            onSelected: (target) =>
                showReportSheet(context, ref, target: target),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const Key('comment-report'),
                value: ReportTarget.comment(
                  programId: programId,
                  date: date,
                  commentId: comment.id,
                ),
                child: const Text('Laporkan komentar'),
              ),
              if (comment.teacherId.isNotEmpty)
                PopupMenuItem(
                  key: const Key('comment-report-user'),
                  value: ReportTarget.user(comment.teacherId, teacher: true),
                  child: const Text('Laporkan pengguna'),
                ),
            ],
          );
    final theme = Theme.of(context);
    final created = comment.createdAt;
    final time = created == null
        ? 'Mengirim…'
        : DateFormat('d MMM y, HH.mm', 'id_ID').format(created.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: context.palette.infoTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 18, color: context.palette.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comment.teacherName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.palette.heading,
                  ),
                ),
              ),
              ?(actions ?? reportMenu),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                SelectableText(
                  comment.text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.edited ? '$time · diubah' : time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
