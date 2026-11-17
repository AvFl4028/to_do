import 'package:material_ui/material_ui.dart';

import '../settings/app_settings.dart';
import 'app_motion.dart';

/// Tema Material 3 de la aplicación, en claro y oscuro.
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF5B5BD6);

  static ThemeData light({
    bool animationsEnabled = true,
    int animationDurationMs = AppSettings.defaultAnimationDurationMs,
  }) => _build(
    Brightness.light,
    animationsEnabled: animationsEnabled,
    animationDurationMs: animationDurationMs,
  );

  static ThemeData dark({
    bool animationsEnabled = true,
    int animationDurationMs = AppSettings.defaultAnimationDurationMs,
  }) => _build(
    Brightness.dark,
    animationsEnabled: animationsEnabled,
    animationDurationMs: animationDurationMs,
  );

  static ThemeData _build(
    Brightness brightness, {
    required bool animationsEnabled,
    required int animationDurationMs,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final pageTransition = AppPageTransitionsBuilder(
      duration: Duration(milliseconds: animationDurationMs),
      enabled: animationsEnabled,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: animationsEnabled ? null : NoSplash.splashFactory,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          for (final platform in TargetPlatform.values)
            platform: pageTransition,
        },
      ),
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
