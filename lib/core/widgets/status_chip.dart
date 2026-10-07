import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../models/student_status.dart';

/// Status is always shown with an icon and text, never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.count});

  final StudentStatus status;

  /// Optional number shown after the label, e.g. on the dashboard.
  final int? count;

  static ({Color text, Color tint, IconData icon}) styleOf(
    StudentStatus status,
  ) => switch (status) {
    StudentStatus.aktif => (
      text: AppColors.activeText,
      tint: AppColors.activeTint,
      icon: Icons.check_circle,
    ),
    StudentStatus.perluPerhatian => (
      text: AppColors.attentionText,
      tint: AppColors.attentionTint,
      icon: Icons.error,
    ),
    StudentStatus.tidakAktif => (
      text: AppColors.inactiveText,
      tint: AppColors.inactiveTint,
      icon: Icons.cancel,
    ),
    StudentStatus.belumMulai => (
      text: AppColors.neutralText,
      tint: AppColors.neutralTint,
      icon: Icons.menu_book,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = styleOf(status);
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
