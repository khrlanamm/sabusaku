import 'package:flutter/material.dart';

import 'colors.dart';
import 'palette.dart';

const _fontFamily = 'Poppins';

/// The default theme.
ThemeData buildAppTheme() => _buildTheme(
  ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.green,
    tertiary: AppColors.amber,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
    error: AppColors.error,
  ),
  background: AppColors.background,
  indicator: AppColors.sky,
  palette: AppPalette.light,
);

/// Deep navy surfaces from the logo with lifted brand accents; designed, not
/// inverted, so every text role keeps AA contrast.
ThemeData buildDarkTheme() => _buildTheme(
  ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.dark,
    primary: AppDarkColors.primary,
    onPrimary: AppDarkColors.onPrimary,
    primaryContainer: AppDarkColors.primaryContainer,
    onPrimaryContainer: AppDarkColors.onPrimaryContainer,
    secondary: AppColors.greenLight,
    onSecondary: const Color(0xFF00391C),
    tertiary: AppColors.amber,
    onTertiary: const Color(0xFF402B00),
    surface: AppDarkColors.surface,
    onSurface: AppDarkColors.ink,
    onSurfaceVariant: AppDarkColors.inkMuted,
    surfaceContainerLowest: AppDarkColors.background,
    surfaceContainerLow: AppDarkColors.surfaceLow,
    surfaceContainer: AppDarkColors.surfaceContainer,
    surfaceContainerHigh: AppDarkColors.surfaceHigh,
    surfaceContainerHighest: AppDarkColors.surfaceHighest,
    outline: AppDarkColors.outline,
    outlineVariant: AppDarkColors.outlineVariant,
    error: AppDarkColors.error,
    onError: AppDarkColors.onError,
    errorContainer: AppDarkColors.errorContainer,
    onErrorContainer: AppDarkColors.onErrorContainer,
    inverseSurface: AppDarkColors.ink,
    onInverseSurface: AppDarkColors.surface,
    inversePrimary: AppColors.blue,
  ),
  background: AppDarkColors.background,
  indicator: AppDarkColors.indicator,
  palette: AppPalette.dark,
);

ThemeData _buildTheme(
  ColorScheme scheme, {
  required Color background,
  required Color indicator,
  required AppPalette palette,
}) {
  final heading = palette.heading;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: background,
  );

  final text = base.textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: heading)
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: heading,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: heading,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: heading,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: heading,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );

  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  // 48dp minimum touch target (PRD: accessibility).
  const minButton = Size(64, 48);
  final outline = BorderSide(color: scheme.outlineVariant);

  return base.copyWith(
    textTheme: text,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: heading,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      // Explicit size: text theme styles carry no font size until they are
      // resolved through Theme.of, so `text.titleLarge` would render at 14.
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: heading,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        side: outline,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        shape: shape,
        foregroundColor: heading,
        side: BorderSide(color: scheme.outline),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: indicator,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? heading
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surface,
      selectedColor: indicator,
      side: BorderSide(color: scheme.outline),
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(color: heading),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: indicator,
        selectedForegroundColor: heading,
        foregroundColor: scheme.onSurfaceVariant,
        side: BorderSide(color: scheme.outline),
        textStyle: text.labelLarge,
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.brightness == Brightness.light
          ? AppColors.navy
          : scheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: scheme.brightness == Brightness.light
            ? Colors.white
            : scheme.onInverseSurface,
      ),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      iconColor: heading,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: scheme.surface,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: palette.track,
    ),
  );
}
