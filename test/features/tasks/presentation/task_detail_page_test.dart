import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:to_do/features/tasks/application/task_store.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/presentation/image_preview_page.dart';
import 'package:to_do/features/tasks/presentation/task_detail_page.dart';

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

  Future<void> pumpDetail(
    WidgetTester tester, {
    String taskId = 'task-1',
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
        home: TaskDetailPage(taskId: taskId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra descripción, fecha, lista, etiquetas y estado', (
    tester,
  ) async {
    final list = buildList(name: 'Trabajo', emoji: '💼');
    final tag = buildTag(name: 'Casa');
    repository.seed(
      tasks: [
        buildTask(
          title: 'Preparar informe',
          description: '# Encabezado\n\nTexto **importante**.',
          dueDate: DateTime(2026, 11, 20),
          listId: list.id,
          tagIds: [tag.id],
        ),
      ],
      lists: [TaskList.inbox(DateTime.utc(2026, 11, 1)), list],
      tags: [tag],
    );
    await store.load();

    await pumpDetail(tester);

    expect(find.text('Preparar informe'), findsOneWidget);
    expect(find.text('Fecha de entrega'), findsOneWidget);
    expect(find.text('20 de noviembre de 2026'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Trabajo'), findsOneWidget);
    expect(find.text('#Casa'), findsOneWidget);
    expect(
      find.textContaining('Encabezado', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('marca la tarea como completada', (tester) async {
    repository.seed(tasks: [buildTask()]);
    await store.load();
    await pumpDetail(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.isCompleted, isTrue);
    expect(find.text('Completada'), findsOneWidget);
  });

  testWidgets('alterna la marca de importante', (tester) async {
    repository.seed(tasks: [buildTask()]);
    await store.load();
    await pumpDetail(tester);

    await tester.tap(find.byTooltip('Marcar como importante'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.isImportant, isTrue);
    expect(find.byTooltip('Quitar de importantes'), findsOneWidget);
  });

  testWidgets('permite quitar la fecha de entrega', (tester) async {
    repository.seed(tasks: [buildTask(dueDate: DateTime(2026, 11, 20))]);
    await store.load();
    await pumpDetail(tester);

    await tester.tap(find.byTooltip('Quitar fecha'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.dueDate, isNull);
    expect(find.text('Sin fecha'), findsOneWidget);
  });

  testWidgets('añade y quita adjuntos', (tester) async {
    final picked = buildAttachment(fileName: 'foto.png');
    final storage = FakeAttachmentStorage(attachmentsToPick: [picked]);
    repository.seed(tasks: [buildTask()]);
    await store.load();
    await pumpDetail(tester, storage: storage);

    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.attachments, hasLength(1));
    expect(find.text('foto.png'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar adjunto'));
    await tester.pumpAndSettle();

    expect(repository.stored.tasks.single.attachments, isEmpty);
    expect(find.text('foto.png'), findsNothing);
  });

  testWidgets('abre los documentos con el programa del sistema', (
    tester,
  ) async {
    final attachment = buildAttachment(
      id: 'doc-1',
      fileName: 'informe.pdf',
      storedName: 'doc-1.pdf',
      extension: 'pdf',
    );
    final storage = FakeAttachmentStorage()
      ..existing.add(attachment.storedName);
    final opener = FakeFileOpener();
    repository.seed(
      tasks: [
        buildTask(attachments: [attachment]),
      ],
    );
    await store.load();
    await pumpDetail(tester, storage: storage, opener: opener);

    await tester.tap(find.text('informe.pdf'));
    await tester.pumpAndSettle();

    expect(opener.opened.single, '/adjuntos/doc-1.pdf');
    expect(find.byType(ImagePreviewPage), findsNothing);
  });

  testWidgets('abre las imágenes en una vista previa interna', (tester) async {
    final attachment = buildAttachment(
      id: 'img-1',
      fileName: 'foto.png',
      storedName: 'img-1.png',
    );
    final storage = FakeAttachmentStorage()
      ..existing.add(attachment.storedName);
    final opener = FakeFileOpener();
    repository.seed(
      tasks: [
        buildTask(attachments: [attachment]),
      ],
    );
    await store.load();
    await pumpDetail(tester, storage: storage, opener: opener);

    await tester.tap(find.text('foto.png'));
    await tester.pumpAndSettle();

    expect(find.byType(ImagePreviewPage), findsOneWidget);
    expect(find.byTooltip('Cerrar vista previa'), findsOneWidget);
    expect(opener.opened, isEmpty);
  });

  testWidgets('avisa si el archivo adjunto ya no existe', (tester) async {
    final attachment = buildAttachment(
      id: 'doc-1',
      fileName: 'perdido.pdf',
      storedName: 'doc-1.pdf',
      extension: 'pdf',
    );
    final storage = FakeAttachmentStorage();
    final opener = FakeFileOpener();
    repository.seed(
      tasks: [
        buildTask(attachments: [attachment]),
      ],
    );
    await store.load();
    await pumpDetail(tester, storage: storage, opener: opener);

    await tester.tap(find.text('perdido.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('El archivo ya no está disponible.'), findsOneWidget);
    expect(opener.opened, isEmpty);
  });

  testWidgets('muestra la tarea inexistente sin romperse', (tester) async {
    await pumpDetail(tester, taskId: 'no-existe');

    expect(find.text('Esta tarea ya no existe.'), findsOneWidget);
  });
}
