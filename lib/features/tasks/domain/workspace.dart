import 'package:logger/logger.dart';

import 'task.dart';
import 'task_list.dart';
import 'task_tag.dart';

/// Contenido completo que se persiste: tareas, listas y etiquetas.
///
/// Se guarda como un único documento versionado para que las tres colecciones
/// se mantengan coherentes entre sí (por ejemplo, al eliminar una lista y mover
/// sus tareas a la bandeja de entrada).
class Workspace {
  Workspace({
    required List<Task> tasks,
    required List<TaskList> lists,
    required List<TaskTag> tags,
  }) : tasks = List<Task>.unmodifiable(tasks),
       lists = List<TaskList>.unmodifiable(lists),
       tags = List<TaskTag>.unmodifiable(tags);

  static const int schemaVersion = 2;

  static final Logger _logger = Logger();

  final List<Task> tasks;
  final List<TaskList> lists;
  final List<TaskTag> tags;

  factory Workspace.empty() =>
      Workspace(tasks: <Task>[], lists: <TaskList>[], tags: <TaskTag>[]);

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      tasks: _decodeList(json['tasks'], Task.fromJson, 'tarea'),
      lists: _decodeList(json['lists'], TaskList.fromJson, 'lista'),
      tags: _decodeList(json['tags'], TaskTag.fromJson, 'etiqueta'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'lists': lists.map((list) => list.toJson()).toList(),
    'tags': tags.map((tag) => tag.toJson()).toList(),
  };

  static List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
    String label,
  ) {
    if (value is! List) {
      return <T>[];
    }

    final items = <T>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        _logger.w('Se omitió un elemento de tipo $label con formato inválido.');
        continue;
      }
      try {
        items.add(decode(item));
      } catch (error, stackTrace) {
        _logger.e(
          'Se omitió un elemento de tipo $label con datos inválidos.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return items;
  }
}
