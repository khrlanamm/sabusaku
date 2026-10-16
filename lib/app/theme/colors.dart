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

/// Dark theme tokens: deep navy surfaces from the logo, light text, and the
/// brand blue/green/amber lifted so they keep AA contrast on dark.
abstract final class AppDarkColors {
  static const background = Color(0xFF0B1524);
  static const surface = Color(0xFF13213A);
  static const surfaceLow = Color(0xFF101C30);
  static const surfaceContainer = Color(0xFF172740);
  static const surfaceHigh = Color(0xFF1C2E4A);
  static const surfaceHighest = Color(0xFF223656);
  static const outline = Color(0xFF3A4D6B);
  static const outlineVariant = Color(0xFF2A3C58);
  static const ink = Color(0xFFE7EDF6);
  static const inkMuted = Color(0xFFA8B5C8);
  static const heading = Color(0xFFD9E5FF);

  static const primary = Color(0xFF8DB2FF);
  static const onPrimary = Color(0xFF0A2457);
  static const primaryContainer = Color(0xFF1E3D73);
  static const onPrimaryContainer = Color(0xFFD9E4FF);
  static const indicator = Color(0xFF24406E);

  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
}
