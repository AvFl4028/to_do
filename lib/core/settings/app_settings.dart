/// Preferencia de tema elegida por el usuario.
enum AppThemePreference { system, light, dark }

/// Ajustes locales de la aplicación: apariencia, movimiento y disposición.
///
/// Se guardan en `shared_preferences` bajo la clave `settings_v1`. Los valores
/// numéricos se normalizan al leerlos para que un documento antiguo o corrupto
/// no rompa la interfaz.
class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.animationsEnabled = true,
    this.animationDurationMs = defaultAnimationDurationMs,
    this.sidebarWidth = defaultSidebarWidth,
    this.panelWidth = defaultPanelWidth,
  });

  static const AppSettings defaults = AppSettings();

  static const int minAnimationDurationMs = 100;
  static const int maxAnimationDurationMs = 600;
  static const int defaultAnimationDurationMs = 250;

  static const double minSidebarWidth = 240;
  static const double maxSidebarWidth = 420;
  static const double defaultSidebarWidth = 300;

  static const double minPanelWidth = 320;
  static const double maxPanelWidth = 560;
  static const double defaultPanelWidth = 400;

  final AppThemePreference themePreference;
  final bool animationsEnabled;
  final int animationDurationMs;
  final double sidebarWidth;
  final double panelWidth;

  Duration get animationDuration => Duration(milliseconds: animationDurationMs);

  /// Duración que deben usar las animaciones de la interfaz.
  Duration get motionDuration =>
      animationsEnabled ? animationDuration : Duration.zero;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    bool? animationsEnabled,
    int? animationDurationMs,
    double? sidebarWidth,
    double? panelWidth,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      animationDurationMs: _clampInt(
        animationDurationMs ?? this.animationDurationMs,
        minAnimationDurationMs,
        maxAnimationDurationMs,
      ),
      sidebarWidth: _clampDouble(
        sidebarWidth ?? this.sidebarWidth,
        minSidebarWidth,
        maxSidebarWidth,
      ),
      panelWidth: _clampDouble(
        panelWidth ?? this.panelWidth,
        minPanelWidth,
        maxPanelWidth,
      ),
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themePreference: _parseThemePreference(json['theme']),
      animationsEnabled: json['animationsEnabled'] is bool
          ? json['animationsEnabled'] as bool
          : true,
      animationDurationMs: _clampInt(
        json['animationDurationMs'] is num
            ? (json['animationDurationMs'] as num).round()
            : defaultAnimationDurationMs,
        minAnimationDurationMs,
        maxAnimationDurationMs,
      ),
      sidebarWidth: _clampDouble(
        json['sidebarWidth'] is num
            ? (json['sidebarWidth'] as num).toDouble()
            : defaultSidebarWidth,
        minSidebarWidth,
        maxSidebarWidth,
      ),
      panelWidth: _clampDouble(
        json['panelWidth'] is num
            ? (json['panelWidth'] as num).toDouble()
            : defaultPanelWidth,
        minPanelWidth,
        maxPanelWidth,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'theme': themePreference.name,
    'animationsEnabled': animationsEnabled,
    'animationDurationMs': animationDurationMs,
    'sidebarWidth': sidebarWidth,
    'panelWidth': panelWidth,
  };

  static AppThemePreference _parseThemePreference(Object? value) {
    return switch (value) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }

  static int _clampInt(int value, int min, int max) =>
      value < min ? min : (value > max ? max : value);

  static double _clampDouble(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppSettings &&
        other.themePreference == themePreference &&
        other.animationsEnabled == animationsEnabled &&
        other.animationDurationMs == animationDurationMs &&
        other.sidebarWidth == sidebarWidth &&
        other.panelWidth == panelWidth;
  }

  @override
  int get hashCode => Object.hash(
    themePreference,
    animationsEnabled,
    animationDurationMs,
    sidebarWidth,
    panelWidth,
  );
}
