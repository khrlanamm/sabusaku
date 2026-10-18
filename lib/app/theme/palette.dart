import 'package:flutter/material.dart';

import 'colors.dart';

/// Colours with a meaning beyond the Material roles: status chips, stat
/// icons, the streak flame, progress tracks. Every text colour reaches WCAG AA
/// (4.5:1) on its tint in both themes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.heading,
    required this.info,
    required this.infoTint,
    required this.success,
    required this.streak,
    required this.track,
    required this.skeleton,
    required this.activeText,
    required this.activeTint,
    required this.attentionText,
    required this.attentionTint,
    required this.inactiveText,
    required this.inactiveTint,
    required this.neutralText,
    required this.neutralTint,
    required this.goldText,
    required this.goldTint,
    required this.silverText,
    required this.silverTint,
    required this.bronzeText,
    required this.bronzeTint,
  });

  /// Titles and emphasised labels (navy on light, pale blue on dark).
  final Color heading;

  /// Accent text and icons on [infoTint] (comments, pills, empty states).
  final Color info;
  final Color infoTint;

  /// Check marks and "selesai" icons.
  final Color success;

  /// The streak flame.
  final Color streak;

  /// Unfilled part of progress bars.
  final Color track;

  /// Loading placeholders.
  final Color skeleton;

  final Color activeText;
  final Color activeTint;
  final Color attentionText;
  final Color attentionTint;
  final Color inactiveText;
  final Color inactiveTint;
  final Color neutralText;
  final Color neutralTint;

  /// Medals of the first three places on a leaderboard (text on tint).
  final Color goldText;
  final Color goldTint;
  final Color silverText;
  final Color silverTint;
  final Color bronzeText;
  final Color bronzeTint;

  static const light = AppPalette(
    heading: AppColors.navy,
    // blueDark, not blue: brand blue is 4.4:1 on sky, just under AA.
    info: AppColors.blueDark,
    infoTint: AppColors.sky,
    success: AppColors.green,
    streak: Color(0xFFD98200),
    track: AppColors.sky,
    skeleton: AppColors.neutralTint,
    activeText: AppColors.activeText,
    activeTint: AppColors.activeTint,
    attentionText: AppColors.attentionText,
    attentionTint: AppColors.attentionTint,
    inactiveText: AppColors.inactiveText,
    inactiveTint: AppColors.inactiveTint,
    neutralText: AppColors.neutralText,
    neutralTint: AppColors.neutralTint,
    goldText: Color(0xFF7A5200),
    goldTint: Color(0xFFFFF0C2),
    silverText: Color(0xFF4A5566),
    silverTint: Color(0xFFE8ECF2),
    bronzeText: Color(0xFF8A4515),
    bronzeTint: Color(0xFFFBE6D6),
  );

  static const dark = AppPalette(
    heading: AppDarkColors.heading,
    info: Color(0xFFA9C6FF),
    infoTint: Color(0xFF1C3054),
    success: AppColors.greenLight,
    streak: AppColors.amber,
    track: Color(0xFF26395A),
    skeleton: Color(0xFF1B2B42),
    activeText: Color(0xFF8BE3AE),
    activeTint: Color(0xFF133826),
    attentionText: Color(0xFFFFD37E),
    attentionTint: Color(0xFF3B2C0B),
    inactiveText: Color(0xFFFFB4AB),
    inactiveTint: Color(0xFF4A1C19),
    neutralText: Color(0xFFC3CDDB),
    neutralTint: Color(0xFF243247),
    goldText: Color(0xFFFFD37E),
    goldTint: Color(0xFF3B2C0B),
    silverText: Color(0xFFD5DCE6),
    silverTint: Color(0xFF2A3445),
    bronzeText: Color(0xFFFFC09A),
    bronzeTint: Color(0xFF43281A),
  );

  @override
  AppPalette copyWith({
    Color? heading,
    Color? info,
    Color? infoTint,
    Color? success,
    Color? streak,
    Color? track,
    Color? skeleton,
    Color? activeText,
    Color? activeTint,
    Color? attentionText,
    Color? attentionTint,
    Color? inactiveText,
    Color? inactiveTint,
    Color? neutralText,
    Color? neutralTint,
    Color? goldText,
    Color? goldTint,
    Color? silverText,
    Color? silverTint,
    Color? bronzeText,
    Color? bronzeTint,
  }) => AppPalette(
    heading: heading ?? this.heading,
    info: info ?? this.info,
    infoTint: infoTint ?? this.infoTint,
    success: success ?? this.success,
    streak: streak ?? this.streak,
    track: track ?? this.track,
    skeleton: skeleton ?? this.skeleton,
    activeText: activeText ?? this.activeText,
    activeTint: activeTint ?? this.activeTint,
    attentionText: attentionText ?? this.attentionText,
    attentionTint: attentionTint ?? this.attentionTint,
    inactiveText: inactiveText ?? this.inactiveText,
    inactiveTint: inactiveTint ?? this.inactiveTint,
    neutralText: neutralText ?? this.neutralText,
    neutralTint: neutralTint ?? this.neutralTint,
    goldText: goldText ?? this.goldText,
    goldTint: goldTint ?? this.goldTint,
    silverText: silverText ?? this.silverText,
    silverTint: silverTint ?? this.silverTint,
    bronzeText: bronzeText ?? this.bronzeText,
    bronzeTint: bronzeTint ?? this.bronzeTint,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      heading: mix(heading, other.heading),
      info: mix(info, other.info),
      infoTint: mix(infoTint, other.infoTint),
      success: mix(success, other.success),
      streak: mix(streak, other.streak),
      track: mix(track, other.track),
      skeleton: mix(skeleton, other.skeleton),
      activeText: mix(activeText, other.activeText),
      activeTint: mix(activeTint, other.activeTint),
      attentionText: mix(attentionText, other.attentionText),
      attentionTint: mix(attentionTint, other.attentionTint),
      inactiveText: mix(inactiveText, other.inactiveText),
      inactiveTint: mix(inactiveTint, other.inactiveTint),
      neutralText: mix(neutralText, other.neutralText),
      neutralTint: mix(neutralTint, other.neutralTint),
      goldText: mix(goldText, other.goldText),
      goldTint: mix(goldTint, other.goldTint),
      silverText: mix(silverText, other.silverText),
      silverTint: mix(silverTint, other.silverTint),
      bronzeText: mix(bronzeText, other.bronzeText),
      bronzeTint: mix(bronzeTint, other.bronzeTint),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The semantic colours of the active theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
