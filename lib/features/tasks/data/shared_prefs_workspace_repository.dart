import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task.dart';
import '../domain/task_list.dart';
import '../domain/task_tag.dart';
import '../domain/workspace.dart';
import 'workspace_repository.dart';

/// Persistencia local del workspace en `shared_preferences`.
///
/// Se guarda un único documento versionado en [storageKey]. Si no existe, se
/// migran automáticamente las tareas de la clave antigua [legacyTasksKey]
/// asignándolas a la bandeja de entrada. La clave antigua se conserva como
/// respaldo.
class SharedPreferencesWorkspaceRepository implements WorkspaceRepository {
  SharedPreferencesWorkspaceRepository(this._preferences);

  static const storageKey = 'workspace_v2';

  /// Clave usada por la primera versión de la aplicación (`tasks_v1`).
  static const legacyTasksKey = 'tasks_v1';

  static final Logger _logger = Logger();

  final SharedPreferences _preferences;

  static Future<SharedPreferencesWorkspaceRepository> create() async {
    return SharedPreferencesWorkspaceRepository(
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<Workspace> load() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      final migrated = _migrateLegacyTasks();
      if (migrated == null) {
        return Workspace.empty();
      }
      // Se guarda de inmediato para que la migración ocurra una sola vez y no
      // se vuelva a leer `tasks_v1` en cada arranque.
      try {
        await save(migrated);
      } catch (error, stackTrace) {
        _logger.e(
          'No se pudo guardar el workspace migrado.',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return migrated;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _logger.w('El workspace guardado no es un objeto JSON.');
        return Workspace.empty();
      }
      return Workspace.fromJson(decoded);
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudo leer el workspace guardado.',
        error: error,
        stackTrace: stackTrace,
      );
      return Workspace.empty();
    }
  }

  @override
  Future<void> save(Workspace workspace) async {
    final encoded = jsonEncode(workspace.toJson());
    final saved = await _preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('No se pudo escribir el workspace.');
    }
  }

  /// Devuelve `null` si no hay datos antiguos que migrar o si no se pudieron
  /// leer, para no sobrescribir el respaldo con un workspace vacío.
  Workspace? _migrateLegacyTasks() {
    final raw = _preferences.getString(legacyTasksKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }

      final tasks = <Task>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        try {
          tasks.add(Task.fromJson(item));
        } catch (error, stackTrace) {
          _logger.e(
            'Se omitió una tarea antigua con datos inválidos.',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      if (tasks.isEmpty) {
        return null;
      }
      _logger.i('Se migraron ${tasks.length} tareas a workspace_v2.');
      return Workspace(tasks: tasks, lists: <TaskList>[], tags: <TaskTag>[]);
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudieron migrar las tareas antiguas.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
