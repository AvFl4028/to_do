import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:to_do/app.dart';
import 'package:to_do/core/settings/app_settings.dart';
import 'package:to_do/core/settings/settings_controller.dart';
import 'package:to_do/features/tasks/application/task_store.dart';

import 'support/in_memory_settings_repository.dart';
import 'support/in_memory_workspace_repository.dart';
import 'support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeSpanishLocale();
  });

  testWidgets('aplica el tema elegido en toda la aplicación', (tester) async {
    final repository = InMemoryWorkspaceRepository();
    final store = TaskStore(repository);
    await store.load();
    final settings = SettingsController(InMemorySettingsRepository());
    addTearDown(store.dispose);
    addTearDown(settings.dispose);

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ToDoApp(store: store, settings: settings));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(settings.settings.themePreference, AppThemePreference.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.byKey(const ValueKey('settings-page'))))
          .brightness,
      Brightness.dark,
    );
  });
}
