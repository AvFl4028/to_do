import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/core/settings/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('usa valores por defecto coherentes', () {
      const settings = AppSettings.defaults;

      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.animationsEnabled, isTrue);
      expect(settings.animationDurationMs, 250);
      expect(settings.sidebarWidth, 300);
      expect(settings.panelWidth, 400);
      expect(settings.motionDuration, const Duration(milliseconds: 250));
    });

    test('normaliza los valores fuera de rango', () {
      final settings = AppSettings.defaults.copyWith(
        animationDurationMs: 5000,
        sidebarWidth: 10,
        panelWidth: 900,
      );

      expect(settings.animationDurationMs, AppSettings.maxAnimationDurationMs);
      expect(settings.sidebarWidth, AppSettings.minSidebarWidth);
      expect(settings.panelWidth, AppSettings.maxPanelWidth);
    });

    test('serializa y restaura todos los ajustes', () {
      const settings = AppSettings(
        themePreference: AppThemePreference.dark,
        animationsEnabled: false,
        animationDurationMs: 400,
        sidebarWidth: 360,
        panelWidth: 480,
      );

      expect(AppSettings.fromJson(settings.toJson()), settings);
      expect(settings.motionDuration, Duration.zero);
    });

    test('tolera documentos antiguos o corruptos', () {
      final settings = AppSettings.fromJson(<String, dynamic>{
        'theme': 'desconocido',
        'animationsEnabled': 'sí',
        'animationDurationMs': 20,
        'sidebarWidth': 999,
        'panelWidth': 1,
      });

      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.animationsEnabled, isTrue);
      expect(settings.animationDurationMs, AppSettings.minAnimationDurationMs);
      expect(settings.sidebarWidth, AppSettings.maxSidebarWidth);
      expect(settings.panelWidth, AppSettings.minPanelWidth);
    });
  });
}
