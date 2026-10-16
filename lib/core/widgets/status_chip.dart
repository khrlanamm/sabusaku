import 'package:flutter/material.dart';

import '../../app/theme/palette.dart';
import '../models/student_status.dart';

/// Status is always shown with an icon and text, never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.count});

  final StudentStatus status;

  /// Optional number shown after the label, e.g. on the dashboard.
  final int? count;

  static ({Color text, Color tint, IconData icon}) styleOf(
    BuildContext context,
    StudentStatus status,
  ) {
    final palette = context.palette;
    return switch (status) {
      StudentStatus.aktif => (
        text: palette.activeText,
        tint: palette.activeTint,
        icon: Icons.check_circle,
      ),
      StudentStatus.perluPerhatian => (
        text: palette.attentionText,
        tint: palette.attentionTint,
        icon: Icons.error,
      ),
      StudentStatus.tidakAktif => (
        text: palette.inactiveText,
        tint: palette.inactiveTint,
        icon: Icons.cancel,
      ),
      StudentStatus.belumMulai => (
        text: palette.neutralText,
        tint: palette.neutralTint,
        icon: Icons.menu_book,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = styleOf(context, status);
    final label = count == null ? status.label : '${status.label} · $count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.text),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.text,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
