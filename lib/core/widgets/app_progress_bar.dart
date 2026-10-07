import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.percent,
    this.color = AppColors.blue,
    this.height = 8,
  });

  /// 0–100.
  final int percent;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = (percent.clamp(0, 100)) / 100;
    return Semantics(
      label: 'Progres $percent persen',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          color: color,
          backgroundColor: AppColors.sky,
        ),
      ),
    );
  }
}
