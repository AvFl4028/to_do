import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/features/tasks/data/shared_prefs_workspace_repository.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';

import '../../../support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late SharedPreferencesWorkspaceRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    repository = SharedPreferencesWorkspaceRepository(preferences);
  });

  test('devuelve un workspace vacío si no hay datos', () async {
    final workspace = await repository.load();

    expect(workspace.tasks, isEmpty);
    expect(workspace.lists, isEmpty);
    expect(workspace.tags, isEmpty);
  });

  test('guarda y recupera el workspace completo', () async {
    final list = buildList();
    final tag = buildTag();
    final task = buildTask(listId: list.id, tagIds: [tag.id]);
    final workspace = buildWorkspace(
      tasks: [task],
      lists: [TaskList.inbox(DateTime.utc(2026, 11, 1)), list],
      tags: [tag],
    );

    await repository.save(workspace);
    final loaded = await repository.load();

    expect(loaded.tasks.single, task);
    expect(loaded.lists, hasLength(2));
    expect(loaded.tags.single, tag);
    expect(
      preferences.getString(SharedPreferencesWorkspaceRepository.storageKey),
      isNotNull,
    );
  });

  test('ignora JSON corrupto sin romper la aplicación', () async {
    await preferences.setString(
      SharedPreferencesWorkspaceRepository.storageKey,
      'esto no es json',
    );

    expect((await repository.load()).tasks, isEmpty);
  });

  test('migra las tareas de tasks_v1 a la bandeja de entrada', () async {
    await preferences.setString(
      SharedPreferencesWorkspaceRepository.legacyTasksKey,
      jsonEncode(<Object>[
        buildTask(id: 'legacy-1', title: 'Tarea antigua').toJson(),
        buildTask(id: 'legacy-2', title: 'Otra tarea').toJson(),
      ]),
    );

    final workspace = await repository.load();

    expect(workspace.tasks, hasLength(2));
    expect(workspace.tasks.first.id, 'legacy-1');
    expect(workspace.tasks.first.listId, TaskList.inboxId);
    expect(workspace.tasks.first.isImportant, isFalse);
    expect(workspace.lists, isEmpty);
    expect(workspace.tags, isEmpty);

    // La clave antigua se conserva como respaldo.
    expect(
      preferences.getString(
        SharedPreferencesWorkspaceRepository.legacyTasksKey,
      ),
      isNotNull,
    );

    // La migración se guarda de inmediato para no repetirse en cada arranque.
    expect(
      preferences.getString(SharedPreferencesWorkspaceRepository.storageKey),
      isNotNull,
    );
  });

  test('la migración omite tareas antiguas inválidas', () async {
    await preferences.setString(
      SharedPreferencesWorkspaceRepository.legacyTasksKey,
      jsonEncode(<Object>[
        buildTask().toJson(),
        <String, Object>{'title': 'sin id'},
      ]),
    );

    final workspace = await repository.load();

    expect(workspace.tasks, hasLength(1));
    expect(workspace.tasks.single.id, 'task-1');
  });

  test('prefiere workspace_v2 cuando ya existe', () async {
    await preferences.setString(
      SharedPreferencesWorkspaceRepository.storageKey,
      jsonEncode(buildWorkspace(tasks: [buildTask(title: 'Nueva')]).toJson()),
    );
    await preferences.setString(
      SharedPreferencesWorkspaceRepository.legacyTasksKey,
      jsonEncode(<Object>[buildTask(title: 'Antigua').toJson()]),
    );

    final workspace = await repository.load();

    expect(workspace.tasks.single.title, 'Nueva');
  });
}
