import 'package:flutter/material.dart';

import '../../app/theme/palette.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final active = days > 0;
    final palette = context.palette;
    final text = active ? palette.attentionText : palette.neutralText;
    return Semantics(
      label: 'Streak $days hari',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? palette.attentionTint : palette.neutralTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: active ? palette.streak : palette.neutralText,
            ),
            const SizedBox(width: 4),
            Text(
              '$days hari',
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
