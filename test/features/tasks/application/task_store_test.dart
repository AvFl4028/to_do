import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/features/tasks/application/task_store.dart';
import 'package:to_do/features/tasks/data/workspace_repository.dart';
import 'package:to_do/features/tasks/domain/task.dart';
import 'package:to_do/features/tasks/domain/task_filter.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/domain/task_view.dart';
import 'package:to_do/features/tasks/domain/workspace.dart';

import '../../../support/in_memory_workspace_repository.dart';
import '../../../support/test_harness.dart';

void main() {
  late InMemoryWorkspaceRepository repository;
  late TaskStore store;
  final now = DateTime.utc(2026, 11, 16, 12);

  setUp(() async {
    repository = InMemoryWorkspaceRepository();
    store = TaskStore(repository, clock: () => now);
    await store.load();
    addTearDown(store.dispose);
  });

  group('carga', () {
    test('crea la bandeja de entrada si no existe', () async {
      expect(store.lists, hasLength(1));
      expect(store.lists.single.isInbox, isTrue);
      expect(store.lists.single.name, TaskList.inboxName);
    });

    test('mueve a la bandeja las tareas con una lista desconocida', () async {
      repository.seed(
        tasks: [buildTask(title: 'Huérfana', listId: 'lista-borrada')],
      );

      await store.load();

      expect(store.allTasks.single.listId, TaskList.inboxId);
    });

    test('expone un error si falla la carga', () async {
      repository.failOnLoad = true;

      await store.load();

      expect(store.isLoading, isFalse);
      expect(store.errorMessage, isNotNull);
      expect(store.allTasks, isEmpty);
      expect(store.lists.single.isInbox, isTrue);
    });
  });

  group('tareas', () {
    test('crea tareas normalizando todos los campos', () async {
      final list = await store.createList(name: 'Trabajo', emoji: '💼');
      final tag = await store.createTag('Casa');

      final task = await store.create(
        title: '  Comprar leche  ',
        description: '  **Dos litros**  ',
        dueDate: DateTime(2026, 11, 20, 18, 30),
        listId: list.id,
        isImportant: true,
        tagIds: [tag.id, tag.id, 'etiqueta-inexistente'],
      );

      expect(task.title, 'Comprar leche');
      expect(task.description, '**Dos litros**');
      expect(task.dueDate, DateTime(2026, 11, 20));
      expect(task.listId, list.id);
      expect(task.isImportant, isTrue);
      expect(task.tagIds, <String>[tag.id]);
      expect(task.createdAt, now);
      expect(task.isCompleted, isFalse);
      expect(repository.stored.tasks.last, task);
    });

    test('actualiza organización, fecha y adjuntos', () async {
      final list = await store.createList(name: 'Trabajo', emoji: '💼');
      final tag = await store.createTag('Casa');
      final attachment = buildAttachment();
      final task = await store.create(title: 'Original');

      await store.updateTask(
        task.id,
        title: 'Editada',
        description: 'Nuevo texto',
        dueDate: DateTime(2026, 11, 25),
        listId: list.id,
        isImportant: true,
        tagIds: [tag.id],
        attachments: [attachment],
      );

      final updated = store.taskById(task.id)!;
      expect(updated.title, 'Editada');
      expect(updated.dueDate, DateTime(2026, 11, 25));
      expect(updated.listId, list.id);
      expect(updated.isImportant, isTrue);
      expect(updated.tagIds, [tag.id]);
      expect(updated.attachments.single, attachment);
      expect(repository.stored.tasks.single.listId, list.id);

      await store.updateTask(
        task.id,
        title: 'Editada',
        description: 'Nuevo texto',
        dueDate: null,
      );

      expect(store.taskById(task.id)!.dueDate, isNull);
    });

    test('alterna completado e importante', () async {
      final task = await store.create(title: 'Tarea');

      await store.toggleCompleted(task.id);
      expect(store.taskById(task.id)!.isCompleted, isTrue);

      await store.toggleImportant(task.id);
      expect(store.taskById(task.id)!.isImportant, isTrue);

      await store.toggleCompleted(task.id);
      await store.toggleImportant(task.id);
      expect(store.taskById(task.id)!.isCompleted, isFalse);
      expect(store.taskById(task.id)!.isImportant, isFalse);
      expect(repository.stored.tasks.single.isCompleted, isFalse);
    });

    test('elimina y deshace conservando todas las tareas', () async {
      final first = await store.create(title: 'Primera');
      final second = await store.create(title: 'Segunda');

      await store.delete(second.id);
      expect(store.visibleTasks.map((task) => task.id), <String>[first.id]);
      expect(store.canUndoDelete, isTrue);

      await store.undoDelete();
      expect(store.visibleTasks, hasLength(2));
      expect(
        store.visibleTasks.map((task) => task.id),
        containsAll(<String>[first.id, second.id]),
      );
      expect(repository.stored.tasks, hasLength(2));
    });

    test('calcula contadores y filtra por estado y vencimiento', () async {
      await store.create(title: 'Vencida', dueDate: DateTime(2026, 11, 10));
      await store.create(title: 'Futura', dueDate: DateTime(2026, 11, 30));
      final completed = await store.create(title: 'Completada');
      await store.toggleCompleted(completed.id);

      expect(store.allTasks, hasLength(3));
      expect(store.pendingCount, 2);
      expect(store.completedCount, 1);
      expect(store.overdueCount, 1);

      store.setFilter(TaskFilter.overdue);
      expect(store.visibleTasks.single.title, 'Vencida');

      store.setFilter(TaskFilter.completed);
      expect(store.visibleTasks.single.title, 'Completada');

      store.setFilter(TaskFilter.pending);
      expect(store.visibleTasks.map((task) => task.title), <String>[
        'Vencida',
        'Futura',
      ]);
    });

    test(
      'ordena pendientes por fecha y deja las completadas al final',
      () async {
        await store.create(title: 'Sin fecha');
        final completed = await store.create(
          title: 'Completada con fecha',
          dueDate: DateTime(2026, 11, 18),
        );
        await store.toggleCompleted(completed.id);
        await store.create(
          title: 'Fecha lejana',
          dueDate: DateTime(2026, 12, 1),
        );
        await store.create(
          title: 'Fecha cercana',
          dueDate: DateTime(2026, 11, 20),
        );

        expect(store.allTasks.map((task) => task.title), <String>[
          'Fecha cercana',
          'Fecha lejana',
          'Sin fecha',
          'Completada con fecha',
        ]);
      },
    );

    test('mantiene la tarea en memoria si falla el guardado', () async {
      repository.failOnSave = true;

      await store.create(title: 'Sin persistir');

      expect(store.errorMessage, isNotNull);
      expect(store.visibleTasks.single.title, 'Sin persistir');
    });

    test(
      'serializa guardados rápidos para no perder el último cambio',
      () async {
        final delayed = _DelayedWorkspaceRepository();
        final queueStore = TaskStore(delayed, clock: () => now);
        await queueStore.load();
        addTearDown(queueStore.dispose);

        final first = queueStore.create(title: 'Uno');
        final second = queueStore.create(title: 'Dos');

        await Future.wait(<Future<Task>>[first, second]);

        expect(delayed.saved, hasLength(2));
        expect(delayed.saved.last.tasks.last.title, 'Dos');
        expect(queueStore.visibleTasks, hasLength(2));
      },
    );
  });

  group('vistas', () {
    test('Hoy muestra solo pendientes que vencen hoy', () async {
      await store.create(title: 'Hoy', dueDate: now);
      await store.create(
        title: 'Mañana',
        dueDate: now.add(const Duration(days: 1)),
      );
      final completed = await store.create(title: 'Hecha hoy', dueDate: now);
      await store.toggleCompleted(completed.id);

      store.setView(const TodayTasksView());

      expect(store.todayCount, 1);
      expect(store.visibleTasks.single.title, 'Hoy');
      expect(store.supportsStatusFilter, isFalse);
    });

    test('Importantes muestra solo pendientes marcadas', () async {
      await store.create(title: 'Normal');
      await store.create(title: 'Importante', isImportant: true);
      final completed = await store.create(
        title: 'Importante completada',
        isImportant: true,
      );
      await store.toggleCompleted(completed.id);

      store.setView(const ImportantTasksView());

      expect(store.importantCount, 1);
      expect(store.visibleTasks.single.title, 'Importante');
    });

    test(
      'las vistas de lista y etiqueta combinan el filtro de estado',
      () async {
        final list = await store.createList(name: 'Trabajo', emoji: '💼');
        final tag = await store.createTag('Casa');
        final pending = await store.create(
          title: 'Pendiente en lista',
          listId: list.id,
          tagIds: [tag.id],
        );
        final completed = await store.create(
          title: 'Completada en lista',
          listId: list.id,
          tagIds: [tag.id],
        );
        await store.toggleCompleted(completed.id);
        await store.create(title: 'Fuera de la lista');

        store.setView(ListTasksView(list.id));
        expect(store.visibleTasks, hasLength(2));
        expect(store.supportsStatusFilter, isTrue);

        store.setFilter(TaskFilter.pending);
        expect(store.visibleTasks.single.id, pending.id);

        store.setView(TagTasksView(tag.id));
        expect(store.visibleTasks, hasLength(2));

        store.setFilter(TaskFilter.completed);
        expect(store.visibleTasks.single.id, completed.id);
      },
    );

    test('cambiar de vista reinicia el filtro', () async {
      final list = await store.createList(name: 'Trabajo', emoji: '💼');
      store.setView(ListTasksView(list.id));
      store.setFilter(TaskFilter.completed);

      store.setView(const AllTasksView());

      expect(store.filter, TaskFilter.all);
    });

    test('activeTitle refleja la vista', () async {
      final list = await store.createList(name: 'Trabajo', emoji: '💼');
      final tag = await store.createTag('Casa');

      expect(store.activeTitle, 'Todas las tareas');

      store.setView(const TodayTasksView());
      expect(store.activeTitle, 'Vence hoy');

      store.setView(ListTasksView(list.id));
      expect(store.activeTitle, 'Trabajo');
      expect(store.activeEmoji, '💼');
      expect(store.defaultListId, list.id);

      store.setView(TagTasksView(tag.id));
      expect(store.activeTitle, '# Casa');
    });
  });

  group('listas', () {
    test('crea, edita y ordena con la bandeja primero', () async {
      final work = await store.createList(name: '  Trabajo  ', emoji: '💼');
      final home = await store.createList(name: 'Casa', emoji: '🏠');

      expect(work.name, 'Trabajo');
      expect(store.lists.map((list) => list.id), <String>[
        TaskList.inboxId,
        work.id,
        home.id,
      ]);
      expect(store.pendingCountForList(work.id), 0);
    });

    test('editar cambia nombre y emoji', () async {
      final list = await store.createList(name: 'Trabajo', emoji: '💼');

      await store.updateList(list.id, name: 'Oficina', emoji: '🏢');

      expect(store.listById(list.id)!.name, 'Oficina');
      expect(store.listById(list.id)!.emoji, '🏢');
      expect(repository.stored.lists, hasLength(2));
    });

    test('eliminar una lista mueve sus tareas a la bandeja', () async {
      final list = await store.createList(name: 'Trabajo', emoji: '💼');
      final task = await store.create(title: 'En lista', listId: list.id);
      store.setView(ListTasksView(list.id));

      await store.deleteList(list.id);

      expect(store.listById(list.id), isNull);
      expect(store.taskById(task.id), isNotNull);
      expect(store.taskById(task.id)!.listId, TaskList.inboxId);
      expect(store.view, const AllTasksView());
    });

    test('la bandeja de entrada no se puede eliminar', () async {
      await store.createList(name: 'Trabajo', emoji: '💼');

      await store.deleteList(TaskList.inboxId);

      expect(store.listById(TaskList.inboxId), isNotNull);
    });
  });

  group('etiquetas', () {
    test('crea etiquetas y evita duplicados por nombre', () async {
      final first = await store.createTag('  Casa ');
      final duplicate = await store.createTag('casa');

      expect(first.name, 'Casa');
      expect(duplicate.id, first.id);
      expect(store.tags, hasLength(1));
      expect(store.tags.single.colorIndex, 0);
    });

    test('renombra etiquetas', () async {
      final tag = await store.createTag('Casa');

      await store.updateTag(tag.id, name: 'Hogar');

      expect(store.tagById(tag.id)!.name, 'Hogar');
    });

    test('eliminar una etiqueta la quita de todas las tareas', () async {
      final tag = await store.createTag('Casa');
      final task = await store.create(title: 'Tarea', tagIds: [tag.id]);
      store.setView(TagTasksView(tag.id));

      await store.deleteTag(tag.id);

      expect(store.tags, isEmpty);
      expect(store.taskById(task.id)!.tagIds, isEmpty);
      expect(store.view, const AllTasksView());
    });

    test('alterna una etiqueta en una tarea', () async {
      final tag = await store.createTag('Casa');
      final task = await store.create(title: 'Tarea');

      await store.toggleTag(task.id, tag.id);
      expect(store.taskById(task.id)!.tagIds, [tag.id]);

      await store.toggleTag(task.id, tag.id);
      expect(store.taskById(task.id)!.tagIds, isEmpty);
    });

    test('cuenta las tareas pendientes por etiqueta', () async {
      final tag = await store.createTag('Casa');
      await store.create(title: 'Pendiente', tagIds: [tag.id]);
      final completed = await store.create(
        title: 'Completada',
        tagIds: [tag.id],
      );
      await store.toggleCompleted(completed.id);

      expect(store.pendingCountForTag(tag.id), 1);
    });
  });

  group('adjuntos', () {
    test(
      'añade y quita adjuntos y expone los archivos referenciados',
      () async {
        final task = await store.create(title: 'Tarea');
        final attachment = buildAttachment();

        await store.addAttachment(task.id, attachment);
        await store.addAttachment(task.id, attachment);

        expect(store.taskById(task.id)!.attachments, hasLength(1));
        expect(store.storedAttachmentNames, <String>{attachment.storedName});

        await store.removeAttachment(task.id, attachment.id);

        expect(store.taskById(task.id)!.attachments, isEmpty);
        expect(store.storedAttachmentNames, isEmpty);
      },
    );
  });
}

class _DelayedWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> saved = <Workspace>[];
  int _calls = 0;

  @override
  Future<Workspace> load() async => Workspace.empty();

  @override
  Future<void> save(Workspace workspace) async {
    _calls++;
    if (_calls == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    saved.add(workspace);
  }
}
