import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:to_do/core/settings/app_settings.dart';
import 'package:to_do/core/settings/settings_controller.dart';
import 'package:to_do/features/tasks/application/task_store.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/domain/task_view.dart';
import 'package:to_do/features/tasks/presentation/tasks_home_page.dart';
import 'package:to_do/features/tasks/presentation/widgets/app_sidebar.dart';

import '../../../support/fake_attachment_service.dart';
import '../../../support/in_memory_workspace_repository.dart';
import '../../../support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryWorkspaceRepository repository;
  late TaskStore store;

  setUpAll(() async {
    await initializeSpanishLocale();
  });

  setUp(() async {
    repository = InMemoryWorkspaceRepository();
    store = TaskStore(repository, clock: () => DateTime.utc(2026, 11, 16, 10));
    await store.load();
    addTearDown(store.dispose);
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    double width = 1200,
    FakeAttachmentStorage? storage,
    SettingsController? settings,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildTestApp(
        store: store,
        storage: storage,
        settings: settings,
        home: const TasksHomePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el estado vacío y permite crear una tarea', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Aún no hay tareas'), findsOneWidget);

    await tester.tap(find.byTooltip('Nueva tarea'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Comprar leche',
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-description-field')),
      '# Lista\n\n- Leche\n- Pan',
    );
    await tester.tap(find.byKey(const ValueKey('task-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Comprar leche'), findsWidgets);
    expect(repository.stored.tasks, hasLength(1));
    expect(
      repository.stored.tasks.single.description,
      '# Lista\n\n- Leche\n- Pan',
    );
  });

  testWidgets('marca una tarea como completada', (tester) async {
    repository.seed(tasks: [buildTask(title: 'Regar plantas')]);
    await store.load();
    await pumpHome(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.isCompleted, isTrue);
  });

  testWidgets('elimina y deshace con la acción del SnackBar', (tester) async {
    repository.seed(tasks: [buildTask(title: 'Tarea eliminable')]);
    await store.load();
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Opciones de la tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks, isEmpty);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.title, 'Tarea eliminable');
    expect(find.text('Tarea eliminable'), findsWidgets);
  });

  testWidgets('en escritorio la sidebar está visible por defecto', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byTooltip('Abrir menú'), findsNothing);

    final sidebar = find.byType(AppSidebar);
    for (final label in <String>[
      'Vence hoy',
      'Importantes',
      'Todas las tareas',
      'LISTAS',
      'ETIQUETAS',
      'Bandeja de entrada',
    ]) {
      expect(
        find.descendant(of: sidebar, matching: find.text(label)),
        findsOneWidget,
        reason: 'La sidebar debe mostrar «$label».',
      );
    }
  });

  testWidgets('la sidebar muestra contadores y no lista tareas', (
    tester,
  ) async {
    final list = buildList(name: 'Trabajo', emoji: '💼');
    repository.seed(
      tasks: [
        buildTask(
          id: 'today',
          title: 'Llamar al cliente',
          dueDate: DateTime(2026, 11, 16),
        ),
        buildTask(
          id: 'important',
          title: 'Preparar propuesta',
          isImportant: true,
          listId: list.id,
        ),
        buildTask(id: 'other', title: 'Comprar pan'),
        buildTask(id: 'done', title: 'Tarea terminada', isCompleted: true),
      ],
      lists: [TaskList.inbox(DateTime.utc(2026, 11, 1)), list],
    );
    await store.load();
    await pumpHome(tester);

    final sidebar = find.byType(AppSidebar);

    // Los contadores de la sidebar solo cuentan tareas pendientes.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('sidebar-nav-today')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('sidebar-nav-important')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('sidebar-nav-all')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('sidebar-list-${list.id}')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    // La sidebar ya no muestra los títulos de las tareas.
    for (final title in <String>[
      'Llamar al cliente',
      'Preparar propuesta',
      'Comprar pan',
      'Tarea terminada',
    ]) {
      expect(
        find.descendant(of: sidebar, matching: find.text(title)),
        findsNothing,
      );
    }
  });

  testWidgets('separa las tareas pendientes de las completadas', (
    tester,
  ) async {
    repository.seed(
      tasks: [
        buildTask(id: 'pending', title: 'Pendiente'),
        buildTask(id: 'done', title: 'Completada', isCompleted: true),
      ],
    );
    await store.load();
    await pumpHome(tester);

    final pendingHeader = find.byKey(
      const ValueKey<String>('section-Pendientes'),
    );
    final completedHeader = find.byKey(
      const ValueKey<String>('section-Completadas'),
    );

    expect(pendingHeader, findsOneWidget);
    expect(completedHeader, findsOneWidget);
    expect(
      find.descendant(of: pendingHeader, matching: find.text('Pendientes (1)')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: completedHeader,
        matching: find.text('Completadas (1)'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(pendingHeader).dy,
      lessThan(tester.getTopLeft(completedHeader).dy),
    );
    expect(
      tester.getTopLeft(find.text('Pendiente')).dy,
      lessThan(tester.getTopLeft(completedHeader).dy),
    );
  });

  testWidgets('borra las completadas y solo las copias de sus adjuntos', (
    tester,
  ) async {
    final completedAttachment = buildAttachment(
      id: 'completed-attachment',
      storedName: 'completed.png',
    );
    final pendingAttachment = buildAttachment(
      id: 'pending-attachment',
      storedName: 'pending.png',
    );
    repository.seed(
      tasks: [
        buildTask(
          id: 'pending',
          title: 'Pendiente',
          attachments: [pendingAttachment],
        ),
        buildTask(
          id: 'done',
          title: 'Completada',
          isCompleted: true,
          attachments: [completedAttachment],
        ),
      ],
    );
    await store.load();
    final storage = FakeAttachmentStorage();
    await pumpHome(tester, storage: storage);

    await tester.tap(
      find.byKey(const ValueKey<String>('delete-completed-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Borrar completadas'), findsOneWidget);

    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.map((task) => task.id), <String>['pending']);
    expect(storage.deleted, contains('completed.png'));
    expect(storage.deleted, isNot(contains('pending.png')));
    expect(find.text('Se eliminó 1 tarea completada'), findsOneWidget);
  });

  testWidgets('en móvil la sidebar empieza oculta y se abre con el menú', (
    tester,
  ) async {
    await pumpHome(tester, width: 500);

    expect(find.byType(AppSidebar), findsNothing);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSidebar), findsOneWidget);
    expect(find.byTooltip('Cerrar menú'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar menú'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSidebar), findsNothing);
  });

  testWidgets('crea una lista desde la sidebar y navega a ella', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Nueva lista'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('list-name-field')),
      'Trabajo',
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(store.lists.any((list) => list.name == 'Trabajo'), isTrue);
    expect(find.text('Trabajo'), findsWidgets);
    expect(store.view, isA<ListTasksView>());
  });

  testWidgets('seleccionar una lista filtra el contenido principal', (
    tester,
  ) async {
    final list = buildList(name: 'Trabajo', emoji: '💼');
    repository.seed(
      tasks: [
        buildTask(id: 'in-list', title: 'En la lista', listId: list.id),
        buildTask(id: 'inbox', title: 'En la bandeja'),
      ],
      lists: [TaskList.inbox(DateTime.utc(2026, 11, 1)), list],
    );
    await store.load();
    await pumpHome(tester);

    await tester.tap(find.byKey(ValueKey<String>('sidebar-list-${list.id}')));
    await tester.pumpAndSettle();

    expect(store.view, ListTasksView(list.id));
    expect(find.text('En la lista'), findsWidgets);
    expect(store.visibleTasks.single.id, 'in-list');
  });

  testWidgets('abre y edita la tarea en el panel derecho', (tester) async {
    repository.seed(tasks: [buildTask(title: 'Abrir en panel')]);
    await store.load();
    await pumpHome(tester);

    await tester.tap(find.text('Abrir en panel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-detail-panel')), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.byTooltip('Editar tarea'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Editada en panel',
    );
    await tester.tap(find.byKey(const ValueKey('task-save-button')));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.title, 'Editada en panel');
    expect(find.byKey(const ValueKey('task-detail-panel')), findsOneWidget);
    expect(find.text('Editada en panel'), findsWidgets);

    await tester.tap(find.byTooltip('Cerrar panel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-detail-panel')), findsNothing);
  });

  testWidgets('redimensiona las barras y guarda los anchos', (tester) async {
    final settings = buildTestSettings();
    addTearDown(settings.dispose);
    repository.seed(tasks: [buildTask(title: 'Con panel')]);
    await store.load();
    await pumpHome(tester, settings: settings);

    final initialSidebar = tester.getSize(
      find.byKey(const ValueKey('app-sidebar-container')),
    );
    expect(initialSidebar.width, AppSettings.defaultSidebarWidth);

    await tester.drag(
      find.byKey(const ValueKey('sidebar-resize-handle')),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();

    final widenedSidebar = tester.getSize(
      find.byKey(const ValueKey('app-sidebar-container')),
    );
    expect(widenedSidebar.width, greaterThan(initialSidebar.width));
    expect(settings.settings.sidebarWidth, widenedSidebar.width);

    await tester.tap(find.text('Con panel'));
    await tester.pumpAndSettle();

    final initialPanel = tester.getSize(
      find.byKey(const ValueKey('task-panel-container')),
    );
    expect(initialPanel.width, AppSettings.defaultPanelWidth);

    await tester.drag(
      find.byKey(const ValueKey('panel-resize-handle')),
      const Offset(-50, 0),
    );
    await tester.pumpAndSettle();

    final widenedPanel = tester.getSize(
      find.byKey(const ValueKey('task-panel-container')),
    );
    expect(widenedPanel.width, greaterThan(initialPanel.width));
    expect(settings.settings.panelWidth, widenedPanel.width);
  });

  testWidgets('restaura los anchos guardados al iniciar', (tester) async {
    final settings = buildTestSettings(
      settings: const AppSettings(sidebarWidth: 360, panelWidth: 480),
    );
    addTearDown(settings.dispose);
    repository.seed(tasks: [buildTask(title: 'Restaurada')]);
    await store.load();
    await pumpHome(tester, settings: settings);

    expect(
      tester.getSize(find.byKey(const ValueKey('app-sidebar-container'))).width,
      360,
    );

    await tester.tap(find.text('Restaurada'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('task-panel-container'))).width,
      480,
    );
  });
}
