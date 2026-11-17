import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/core/settings/app_settings.dart';
import 'package:to_do/core/settings/settings_controller.dart';

import '../../support/in_memory_settings_repository.dart';

void main() {
  group('SettingsController', () {
    test('carga los ajustes guardados', () async {
      final repository = InMemorySettingsRepository(
        initial: const AppSettings(themePreference: AppThemePreference.dark),
      );
      final controller = SettingsController(repository);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.settings.themePreference, AppThemePreference.dark);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('persiste tema, animaciones y duración', () async {
      final repository = InMemorySettingsRepository();
      final controller = SettingsController(repository);
      addTearDown(controller.dispose);

      await controller.setThemePreference(AppThemePreference.light);
      await controller.setAnimationsEnabled(false);
      await controller.setAnimationDurationMs(600);

      expect(controller.settings.themePreference, AppThemePreference.light);
      expect(controller.settings.animationsEnabled, isFalse);
      expect(controller.settings.animationDurationMs, 600);
      expect(repository.saved, controller.settings);
      expect(repository.saveCount, greaterThanOrEqualTo(1));
    });

    test('persiste los anchos de las barras laterales', () async {
      final repository = InMemorySettingsRepository();
      final controller = SettingsController(repository);
      addTearDown(controller.dispose);

      await controller.setSidebarWidth(360);
      await controller.setPanelWidth(520);

      expect(controller.settings.sidebarWidth, 360);
      expect(controller.settings.panelWidth, 520);
      expect(repository.saved?.sidebarWidth, 360);
      expect(repository.saved?.panelWidth, 520);
    });

    test('no notifica ni guarda cuando el valor no cambia', () async {
      final repository = InMemorySettingsRepository();
      final controller = SettingsController(repository);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setThemePreference(AppThemePreference.system);

      expect(notifications, 0);
      expect(repository.saveCount, 0);
    });
  });
}
