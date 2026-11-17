import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:to_do/core/settings/app_settings.dart';
import 'package:to_do/core/settings/settings_controller.dart';
import 'package:to_do/features/settings/presentation/settings_page.dart';
import 'package:to_do/features/tasks/application/task_store.dart';

import '../../../support/in_memory_settings_repository.dart';
import '../../../support/in_memory_workspace_repository.dart';
import '../../../support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySettingsRepository repository;
  late SettingsController controller;
  late InMemoryWorkspaceRepository workspaceRepository;
  late TaskStore store;

  setUpAll(() async {
    await initializeSpanishLocale();
  });

  setUp(() async {
    repository = InMemorySettingsRepository();
    controller = SettingsController(repository);
    workspaceRepository = InMemoryWorkspaceRepository();
    store = TaskStore(workspaceRepository);
    await store.load();
    addTearDown(controller.dispose);
    addTearDown(store.dispose);
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildTestApp(
        store: store,
        settings: controller,
        home: const SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cambia el tema desde el selector', (tester) async {
    await pumpSettings(tester);

    expect(
      find.byKey(const ValueKey('settings-theme-selector')),
      findsOneWidget,
    );
    expect(controller.settings.themePreference, AppThemePreference.system);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(controller.settings.themePreference, AppThemePreference.dark);
    expect(repository.saved?.themePreference, AppThemePreference.dark);

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();

    expect(controller.settings.themePreference, AppThemePreference.light);
  });

  testWidgets('desactiva las animaciones y la duración', (tester) async {
    await pumpSettings(tester);

    expect(
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('settings-duration-slider')),
          )
          .onChanged,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('settings-animations-switch')));
    await tester.pumpAndSettle();

    expect(controller.settings.animationsEnabled, isFalse);
    expect(repository.saved?.animationsEnabled, isFalse);
    expect(
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('settings-duration-slider')),
          )
          .onChanged,
      isNull,
    );
  });
}
