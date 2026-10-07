import 'package:flutter/material.dart';

/// Tokens taken from the logo palette (branding/README.md).
abstract final class AppColors {
  static const navy = Color(0xFF17365D);
  static const navyDeep = Color(0xFF0F2747);
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4FC4);
  static const sky = Color(0xFFE4EEFF);
  static const green = Color(0xFF2FA866);
  static const greenLight = Color(0xFF5CD08A);
  static const amber = Color(0xFFF5B942);

  static const background = Color(0xFFF6F8FC);
  static const surface = Colors.white;
  static const outline = Color(0xFFD9E1EC);
  static const ink = Color(0xFF14233A);
  static const inkMuted = Color(0xFF55647A);
  static const error = Color(0xFFB3261E);

  // Status pairs (text on tint) chosen to keep AA contrast.
  static const activeText = Color(0xFF1B6B40);
  static const activeTint = Color(0xFFE3F5EA);
  static const attentionText = Color(0xFF7A4E00);
  static const attentionTint = Color(0xFFFFF1CC);
  static const inactiveText = Color(0xFFA1241D);
  static const inactiveTint = Color(0xFFFDE7E6);
  static const neutralText = Color(0xFF465163);
  static const neutralTint = Color(0xFFECEFF4);
}
