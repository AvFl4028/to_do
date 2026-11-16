import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:to_do/features/tasks/application/task_store.dart';
import 'package:to_do/features/tasks/domain/task.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/presentation/task_form_page.dart';

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
    store = TaskStore(repository);
    await store.load();
    addTearDown(store.dispose);
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    Task? task,
    FakeAttachmentStorage? storage,
    FakeFileOpener? opener,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildTestApp(
        store: store,
        storage: storage,
        opener: opener,
        home: TaskFormPage(task: task),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('valida que el título sea obligatorio', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.byKey(const ValueKey('task-save-button')));
    await tester.pump();

    expect(find.text('Escribe un título para la tarea.'), findsOneWidget);
  });

  testWidgets('previsualiza la descripción como Markdown', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Tarea con Markdown',
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-description-field')),
      '## Hola **mundo**\n\n- Uno\n- Dos',
    );

    await tester.tap(find.text('Vista previa'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hola', findRichText: true), findsOneWidget);
    expect(find.textContaining('mundo', findRichText: true), findsOneWidget);
  });

  testWidgets('precarga lista, fecha, importancia y etiquetas', (tester) async {
    final now = DateTime.utc(2026, 11, 1);
    final list = buildList(name: 'Trabajo', emoji: '💼');
    final tag = buildTag(name: 'Casa');
    repository.seed(lists: [TaskList.inbox(now), list], tags: [tag]);
    await store.load();

    final task = buildTask(
      title: 'Tarea existente',
      description: 'Texto previo',
      dueDate: DateTime(2026, 11, 20),
      listId: list.id,
      isImportant: true,
      tagIds: [tag.id],
      createdAt: now,
    );

    await pumpForm(tester, task: task);

    expect(find.text('Tarea existente'), findsOneWidget);
    expect(find.text('20 de noviembre de 2026'), findsOneWidget);
    expect(find.text('Trabajo'), findsOneWidget);
    expect(find.text('#Casa'), findsOneWidget);
    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('task-important-field')),
    );
    expect(switchTile.value, isTrue);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('permite cambiar de lista', (tester) async {
    final list = buildList(name: 'Casa', emoji: '🏠');
    repository.seed(lists: [TaskList.inbox(DateTime.utc(2026, 11, 1)), list]);
    await store.load();
    await pumpForm(tester);

    await tester.tap(find.byKey(const ValueKey('task-list-field')));
    await tester.pumpAndSettle();

    expect(find.text('Elegir lista'), findsOneWidget);

    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('🏠'), findsOneWidget);
  });

  testWidgets('permite asignar una etiqueta existente', (tester) async {
    final tag = buildTag(name: 'Casa');
    repository.seed(tags: [tag]);
    await store.load();
    await pumpForm(tester);

    await tester.tap(find.byKey(const ValueKey('task-tags-button')));
    await tester.pumpAndSettle();

    expect(find.text('#Casa'), findsOneWidget);

    await tester.tap(find.text('#Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(find.text('#Casa'), findsOneWidget);
  });

  testWidgets('añade un adjunto y lo quita antes de guardar', (tester) async {
    final attachment = buildAttachment(fileName: 'foto.png');
    final storage = FakeAttachmentStorage(attachmentsToPick: [attachment]);
    await pumpForm(tester, storage: storage);

    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    expect(find.text('foto.png'), findsOneWidget);
    expect(storage.pickCalls, 1);

    await tester.tap(find.byTooltip('Quitar adjunto'));
    await tester.pumpAndSettle();

    expect(find.text('foto.png'), findsNothing);
    expect(storage.deleted, contains(attachment.storedName));
  });

  testWidgets('al descartar elimina los adjuntos recién copiados', (
    tester,
  ) async {
    final attachment = buildAttachment(fileName: 'nuevo.png');
    final storage = FakeAttachmentStorage(attachmentsToPick: [attachment]);

    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildTestApp(
        store: store,
        storage: storage,
        home: _FormLauncher(builder: (context) => const TaskFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir formulario'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Borrador',
    );
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('nuevo.png'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(storage.deleted, contains(attachment.storedName));
    expect(find.text('Abrir formulario'), findsOneWidget);
  });
}

class _FormLauncher extends StatelessWidget {
  const _FormLauncher({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (innerContext) => FilledButton(
            onPressed: () =>
                Navigator.of(innerContext)
                    .push<void>(MaterialPageRoute<void>(builder: builder)),
            child: const Text('Abrir formulario'),
          ),
        ),
      ),
    );
  }
}
