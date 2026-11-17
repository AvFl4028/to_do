import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../data/workspace_repository.dart';
import '../domain/attachment.dart';
import '../domain/task.dart';
import '../domain/task_filter.dart';
import '../domain/task_list.dart';
import '../domain/task_tag.dart';
import '../domain/task_view.dart';
import '../domain/workspace.dart';

/// Estado observable del workspace: tareas, listas y etiquetas.
///
/// Mantiene todo en memoria, calcula las vistas de la sidebar y persiste cada
/// cambio como un único documento. Si el guardado falla, el cambio permanece
/// visible y se expone [errorMessage] para avisar al usuario.
class TaskStore extends ChangeNotifier {
  TaskStore(this._repository, {DateTime Function()? clock, Uuid? uuid})
    : _clock = clock ?? DateTime.now,
      _uuid = uuid ?? const Uuid();

  final WorkspaceRepository _repository;
  final DateTime Function() _clock;
  final Uuid _uuid;

  /// Reloj actual del store, usado también por las etiquetas de fecha.
  DateTime get now => _clock();

  static final Logger _logger = Logger();

  List<Task> _tasks = <Task>[];
  List<TaskList> _lists = <TaskList>[];
  List<TaskTag> _tags = <TaskTag>[];
  TaskView _view = const AllTasksView();
  TaskFilter _filter = TaskFilter.all;
  bool _isLoading = true;
  String? _errorMessage;
  _DeletedTask? _lastDeleted;
  final List<Workspace> _pendingSaves = <Workspace>[];
  Future<void>? _saveDrain;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskFilter get filter => _filter;
  TaskView get view => _view;
  bool get canUndoDelete => _lastDeleted != null;

  /// Las vistas de Hoy e Importantes ya limitan por estado, así que ocultan la
  /// barra de filtros para no mostrar opciones sin sentido.
  bool get supportsStatusFilter => switch (_view) {
    AllTasksView() || ListTasksView() || TagTasksView() => true,
    TodayTasksView() || ImportantTasksView() => false,
  };

  List<TaskList> get lists {
    // Se ordena por fecha de creación y, en empate, por el orden en que se
    // añadieron, para que las listas no cambien de sitio al renombrarlas.
    final indexes = <String, int>{
      for (var index = 0; index < _lists.length; index++)
        _lists[index].id: index,
    };
    final sorted = <TaskList>[..._lists];
    sorted.sort((a, b) {
      if (a.isInbox != b.isInbox) {
        return a.isInbox ? -1 : 1;
      }
      final comparison = a.createdAt.compareTo(b.createdAt);
      if (comparison != 0) {
        return comparison;
      }
      return (indexes[a.id] ?? 0).compareTo(indexes[b.id] ?? 0);
    });
    return List<TaskList>.unmodifiable(sorted);
  }

  List<TaskTag> get tags {
    final sorted = <TaskTag>[..._tags];
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<TaskTag>.unmodifiable(sorted);
  }

  List<Task> get allTasks => List<Task>.unmodifiable(_sorted(_tasks));

  List<Task> get todayTasks => List<Task>.unmodifiable(
    _sorted(
      _tasks.where(
        (task) =>
            !task.isCompleted &&
            task.dueDate != null &&
            _isToday(task.dueDate!),
      ),
    ),
  );

  List<Task> get importantTasks => List<Task>.unmodifiable(
    _sorted(_tasks.where((task) => !task.isCompleted && task.isImportant)),
  );

  List<Task> get visibleTasks {
    final Iterable<Task> base = _viewTasks();
    final Iterable<Task> filtered = supportsStatusFilter
        ? base.where(_matchesFilter)
        : base;
    return List<Task>.unmodifiable(_sorted(filtered));
  }

  /// Tareas completadas que pertenecen a la vista actual, sin aplicar el
  /// filtro de estado. Es la base del borrado masivo de completadas.
  List<Task> get completedInView => List<Task>.unmodifiable(
    _sorted(_viewTasks().where((task) => task.isCompleted)),
  );

  Map<TaskFilter, int> get filterCounts {
    final base = _viewTasks().toList();
    return <TaskFilter, int>{
      TaskFilter.all: base.length,
      TaskFilter.pending: base.where((task) => !task.isCompleted).length,
      TaskFilter.completed: base.where((task) => task.isCompleted).length,
      TaskFilter.overdue: base.where(isOverdue).length,
    };
  }

  int get pendingCount => _tasks.where((task) => !task.isCompleted).length;

  int get completedCount => _tasks.where((task) => task.isCompleted).length;

  int get overdueCount => _tasks.where(isOverdue).length;

  int get todayCount => todayTasks.length;

  int get importantCount => importantTasks.length;

  String get activeTitle => switch (_view) {
    AllTasksView() => 'Todas las tareas',
    TodayTasksView() => 'Vence hoy',
    ImportantTasksView() => 'Importantes',
    ListTasksView(:final listId) => listById(listId)?.name ?? 'Lista',
    TagTasksView(:final tagId) => '# ${tagById(tagId)?.name ?? 'Etiqueta'}',
  };

  String? get activeEmoji => switch (_view) {
    ListTasksView(:final listId) => listById(listId)?.emoji,
    _ => null,
  };

  /// Lista preseleccionada al crear una tarea desde la vista actual.
  String get defaultListId => switch (_view) {
    ListTasksView(:final listId) => listId,
    _ => TaskList.inboxId,
  };

  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  TaskList? listById(String id) {
    for (final list in _lists) {
      if (list.id == id) {
        return list;
      }
    }
    return null;
  }

  TaskTag? tagById(String id) {
    for (final tag in _tags) {
      if (tag.id == id) {
        return tag;
      }
    }
    return null;
  }

  TaskTag? findTagByName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final tag in _tags) {
      if (tag.name.toLowerCase() == normalized) {
        return tag;
      }
    }
    return null;
  }

  List<Task> tasksInList(String listId) =>
      List<Task>.unmodifiable(_sorted(_tasks.where((t) => t.listId == listId)));

  List<Task> tasksWithTag(String tagId) => List<Task>.unmodifiable(
    _sorted(_tasks.where((t) => t.tagIds.contains(tagId))),
  );

  int pendingCountForList(String listId) =>
      _tasks.where((task) => task.listId == listId && !task.isCompleted).length;

  int pendingCountForTag(String tagId) => _tasks
      .where((task) => task.tagIds.contains(tagId) && !task.isCompleted)
      .length;

  /// Nombres de archivo referenciados por alguna tarea. Se usa al arrancar para
  /// eliminar adjuntos huérfanos sin romper las tareas existentes.
  Set<String> get storedAttachmentNames => <String>{
    for (final task in _tasks)
      for (final attachment in task.attachments) attachment.storedName,
  };

  bool isOverdue(Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null || task.isCompleted) {
      return false;
    }
    final today = _normalizeDate(_clock())!;
    return _normalizeDate(dueDate)!.isBefore(today);
  }

  /// Indica si una tarea pendiente vence hoy y su hora ya pasó.
  ///
  /// No cambia el estado «Vencida» ni los filtros, que siguen siendo por día.
  bool isTimePast(Task task) {
    final dueDate = task.dueDate;
    final dueTimeMinutes = task.dueTimeMinutes;
    if (dueDate == null || dueTimeMinutes == null || task.isCompleted) {
      return false;
    }
    if (!_isToday(dueDate)) {
      return false;
    }
    final now = _clock();
    return now.hour * 60 + now.minute > dueTimeMinutes;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final workspace = await _repository.load();
      _lists = _normalizeLists(workspace.lists);
      _tags = <TaskTag>[...workspace.tags];
      _tasks = _normalizeTasks(workspace.tasks);
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudieron cargar las tareas.',
        error: error,
        stackTrace: stackTrace,
      );
      _lists = _normalizeLists(const <TaskList>[]);
      _tags = <TaskTag>[];
      _tasks = <Task>[];
      _errorMessage = 'No se pudieron cargar las tareas guardadas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task> create({
    required String title,
    String description = '',
    DateTime? dueDate,
    int? dueTimeMinutes,
    String? listId,
    bool isImportant = false,
    List<String> tagIds = const <String>[],
    List<Attachment> attachments = const <Attachment>[],
  }) async {
    final trimmedTitle = title.trim();
    assert(
      trimmedTitle.isNotEmpty,
      'El título de la tarea no puede estar vacío.',
    );

    final now = _clock().toUtc();
    final normalizedDate = _normalizeDate(dueDate);
    final task = Task(
      id: _uuid.v4(),
      title: trimmedTitle,
      description: description.trim(),
      dueDate: normalizedDate,
      dueTimeMinutes: _normalizeDueTime(normalizedDate, dueTimeMinutes),
      listId: _resolveListId(listId),
      isImportant: isImportant,
      tagIds: _normalizeTagIds(tagIds),
      attachments: _normalizeAttachments(attachments),
      createdAt: now,
      updatedAt: now,
    );

    _tasks = <Task>[..._tasks, task];
    await _commit();
    return task;
  }

  Future<void> updateTask(
    String id, {
    required String title,
    required String description,
    DateTime? dueDate,
    int? dueTimeMinutes,
    String? listId,
    bool? isImportant,
    List<String>? tagIds,
    List<Attachment>? attachments,
  }) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    final normalizedDate = _normalizeDate(dueDate);
    _tasks = <Task>[..._tasks]
      ..[index] = _tasks[index].copyWith(
        title: title.trim(),
        description: description.trim(),
        dueDate: normalizedDate,
        clearDueDate: dueDate == null,
        dueTimeMinutes: _normalizeDueTime(normalizedDate, dueTimeMinutes),
        clearDueTime: dueTimeMinutes == null,
        listId: listId == null ? null : _resolveListId(listId),
        isImportant: isImportant,
        tagIds: tagIds == null ? null : _normalizeTagIds(tagIds),
        attachments: attachments == null
            ? null
            : _normalizeAttachments(attachments),
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<void> toggleCompleted(String id) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    _tasks = <Task>[..._tasks]
      ..[index] = task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<void> toggleImportant(String id) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    _tasks = <Task>[..._tasks]
      ..[index] = task.copyWith(
        isImportant: !task.isImportant,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<void> setDueDate(String id, DateTime? dueDate) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    _tasks = <Task>[..._tasks]
      ..[index] = _tasks[index].copyWith(
        dueDate: _normalizeDate(dueDate),
        clearDueDate: dueDate == null,
        clearDueTime: dueDate == null,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  /// Cambia solo la hora de entrega. Si la tarea no tiene fecha, no se aplica.
  Future<void> setDueTime(String id, int? dueTimeMinutes) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    final normalized = _normalizeDueTime(task.dueDate, dueTimeMinutes);
    if (task.dueTimeMinutes == normalized) {
      return;
    }

    _tasks = <Task>[..._tasks]
      ..[index] = task.copyWith(
        dueTimeMinutes: normalized,
        clearDueTime: normalized == null,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<void> setList(String id, String listId) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }
    final resolved = _resolveListId(listId);
    if (_tasks[index].listId == resolved) {
      return;
    }

    _tasks = <Task>[..._tasks]
      ..[index] = _tasks[index].copyWith(
        listId: resolved,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<void> toggleTag(String taskId, String tagId) async {
    final index = _indexOf(taskId);
    if (index == -1 || tagById(tagId) == null) {
      return;
    }

    final task = _tasks[index];
    final ids = <String>[...task.tagIds];
    if (!ids.remove(tagId)) {
      ids.add(tagId);
    }

    _tasks = <Task>[..._tasks]
      ..[index] = task.copyWith(tagIds: ids, updatedAt: _clock().toUtc());
    await _commit();
  }

  Future<void> addAttachment(String taskId, Attachment attachment) async {
    final index = _indexOf(taskId);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    if (task.attachments.any((item) => item.id == attachment.id)) {
      return;
    }

    _tasks = <Task>[..._tasks]
      ..[index] = task.copyWith(
        attachments: <Attachment>[...task.attachments, attachment],
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<void> removeAttachment(String taskId, String attachmentId) async {
    final index = _indexOf(taskId);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    final remaining = task.attachments
        .where((item) => item.id != attachmentId)
        .toList(growable: false);
    if (remaining.length == task.attachments.length) {
      return;
    }

    _tasks = <Task>[..._tasks]
      ..[index] = task.copyWith(
        attachments: remaining,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  Future<TaskList> createList({
    required String name,
    required String emoji,
  }) async {
    final trimmed = name.trim();
    assert(trimmed.isNotEmpty, 'El nombre de la lista no puede estar vacío.');

    final now = _clock().toUtc();
    final list = TaskList(
      id: _uuid.v4(),
      name: trimmed,
      emoji: emoji,
      createdAt: now,
      updatedAt: now,
    );

    _lists = <TaskList>[..._lists, list];
    await _commit();
    return list;
  }

  Future<void> updateList(
    String id, {
    required String name,
    required String emoji,
  }) async {
    final index = _listIndexOf(id);
    if (index == -1) {
      return;
    }

    _lists = <TaskList>[..._lists]
      ..[index] = _lists[index].copyWith(
        name: name.trim(),
        emoji: emoji,
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  /// Elimina la lista y mueve sus tareas a la bandeja de entrada. La bandeja de
  /// entrada no se puede eliminar.
  Future<void> deleteList(String id) async {
    if (id == TaskList.inboxId) {
      return;
    }
    final index = _listIndexOf(id);
    if (index == -1) {
      return;
    }

    _lists = <TaskList>[..._lists]..removeAt(index);
    final now = _clock().toUtc();
    _tasks = <Task>[
      for (final task in _tasks)
        if (task.listId == id)
          task.copyWith(listId: TaskList.inboxId, updatedAt: now)
        else
          task,
    ];
    if (_view == ListTasksView(id)) {
      _view = const AllTasksView();
    }
    await _commit();
  }

  Future<TaskTag> createTag(String name) async {
    final trimmed = name.trim();
    assert(
      trimmed.isNotEmpty,
      'El nombre de la etiqueta no puede estar vacío.',
    );

    final existing = findTagByName(trimmed);
    if (existing != null) {
      return existing;
    }

    final now = _clock().toUtc();
    final tag = TaskTag(
      id: _uuid.v4(),
      name: trimmed,
      colorIndex: _nextColorIndex(),
      createdAt: now,
      updatedAt: now,
    );

    _tags = <TaskTag>[..._tags, tag];
    await _commit();
    return tag;
  }

  Future<void> updateTag(String id, {required String name}) async {
    final index = _tagIndexOf(id);
    if (index == -1) {
      return;
    }

    _tags = <TaskTag>[..._tags]
      ..[index] = _tags[index].copyWith(
        name: name.trim(),
        updatedAt: _clock().toUtc(),
      );
    await _commit();
  }

  /// Elimina la etiqueta y la quita de todas las tareas.
  Future<void> deleteTag(String id) async {
    final index = _tagIndexOf(id);
    if (index == -1) {
      return;
    }

    _tags = <TaskTag>[..._tags]..removeAt(index);
    final now = _clock().toUtc();
    _tasks = <Task>[
      for (final task in _tasks)
        if (task.tagIds.contains(id))
          task.copyWith(
            tagIds: task.tagIds.where((tagId) => tagId != id).toList(),
            updatedAt: now,
          )
        else
          task,
    ];
    if (_view == TagTasksView(id)) {
      _view = const AllTasksView();
    }
    await _commit();
  }

  Future<void> delete(String id) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    _lastDeleted = _DeletedTask(task: _tasks[index], index: index);
    _tasks = <Task>[..._tasks]..removeAt(index);
    await _commit();
  }

  Future<void> undoDelete() async {
    final deleted = _lastDeleted;
    if (deleted == null) {
      return;
    }

    _lastDeleted = null;
    final restored = <Task>[..._tasks];
    final index = deleted.index < 0
        ? 0
        : (deleted.index > restored.length ? restored.length : deleted.index);
    final task = listById(deleted.task.listId) == null
        ? deleted.task.copyWith(listId: TaskList.inboxId)
        : deleted.task;
    restored.insert(index, task);
    _tasks = restored;
    await _commit();
  }

  /// Elimina las tareas completadas de la vista actual y devuelve las que se
  /// quitaron. No toca los archivos adjuntos: la capa de presentación decide
  /// qué copias internas borrar.
  Future<List<Task>> deleteCompletedInView() async {
    final completed = _viewTasks()
        .where((task) => task.isCompleted)
        .toList(growable: false);
    if (completed.isEmpty) {
      return const <Task>[];
    }

    final ids = <String>{for (final task in completed) task.id};
    // El borrado masivo no se puede deshacer con el SnackBar individual.
    _lastDeleted = null;
    _tasks = _tasks.where((task) => !ids.contains(task.id)).toList();
    await _commit();
    return completed;
  }

  void setView(TaskView view) {
    if (_view == view) {
      return;
    }
    _view = view;
    _filter = TaskFilter.all;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Iterable<Task> _viewTasks() => switch (_view) {
    AllTasksView() => _tasks,
    TodayTasksView() => _tasks.where(
      (task) =>
          !task.isCompleted && task.dueDate != null && _isToday(task.dueDate!),
    ),
    ImportantTasksView() => _tasks.where(
      (task) => !task.isCompleted && task.isImportant,
    ),
    ListTasksView(:final listId) => _tasks.where(
      (task) => task.listId == listId,
    ),
    TagTasksView(:final tagId) => _tasks.where(
      (task) => task.tagIds.contains(tagId),
    ),
  };

  bool _matchesFilter(Task task) => switch (_filter) {
    TaskFilter.all => true,
    TaskFilter.pending => !task.isCompleted,
    TaskFilter.completed => task.isCompleted,
    TaskFilter.overdue => isOverdue(task),
  };

  bool _isToday(DateTime date) {
    final today = _normalizeDate(_clock())!;
    return _normalizeDate(date) == today;
  }

  int _indexOf(String id) => _tasks.indexWhere((task) => task.id == id);

  int _listIndexOf(String id) => _lists.indexWhere((list) => list.id == id);

  int _tagIndexOf(String id) => _tags.indexWhere((tag) => tag.id == id);

  String _resolveListId(String? listId) {
    if (listId == null || listById(listId) == null) {
      return TaskList.inboxId;
    }
    return listId;
  }

  List<String> _normalizeTagIds(List<String> tagIds) {
    final result = <String>[];
    for (final id in tagIds) {
      if (tagById(id) != null && !result.contains(id)) {
        result.add(id);
      }
    }
    return result;
  }

  List<Attachment> _normalizeAttachments(List<Attachment> attachments) {
    final result = <Attachment>[];
    for (final attachment in attachments) {
      if (!result.any((item) => item.id == attachment.id)) {
        result.add(attachment);
      }
    }
    return result;
  }

  List<TaskList> _normalizeLists(List<TaskList> source) {
    final lists = <TaskList>[...source];
    final inboxIndex = lists.indexWhere((list) => list.id == TaskList.inboxId);
    if (inboxIndex == -1) {
      lists.insert(0, TaskList.inbox(_clock()));
    } else if (inboxIndex != 0) {
      lists.insert(0, lists.removeAt(inboxIndex));
    }
    return lists;
  }

  List<Task> _normalizeTasks(List<Task> source) {
    final knownLists = <String>{for (final list in _lists) list.id};
    return <Task>[
      for (final task in source)
        if (knownLists.contains(task.listId))
          task
        else
          task.copyWith(listId: TaskList.inboxId),
    ];
  }

  int _nextColorIndex() {
    final used = <int>{for (final tag in _tags) tag.colorIndex};
    for (var index = 0; index < TaskTag.paletteSize; index++) {
      if (!used.contains(index)) {
        return index;
      }
    }
    return _tags.length % TaskTag.paletteSize;
  }

  List<Task> _sorted(Iterable<Task> source) {
    final tasks = source.toList()..sort(_compareTasks);
    return tasks;
  }

  int _compareTasks(Task a, Task b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    if (a.dueDate != null && b.dueDate != null) {
      final comparison = a.dueDate!.compareTo(b.dueDate!);
      if (comparison != 0) {
        return comparison;
      }
      final aTime = a.dueTimeMinutes ?? -1;
      final bTime = b.dueTimeMinutes ?? -1;
      if (aTime != bTime) {
        return aTime.compareTo(bTime);
      }
    } else if (a.dueDate != null) {
      return -1;
    } else if (b.dueDate != null) {
      return 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  DateTime? _normalizeDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day);
  }

  int? _normalizeDueTime(DateTime? dueDate, int? minutes) {
    if (dueDate == null || minutes == null) {
      return null;
    }
    if (minutes < 0 || minutes >= 24 * 60) {
      return null;
    }
    return minutes;
  }

  Future<void> _commit() {
    notifyListeners();

    // Encola el guardado para que dos cambios rápidos no puedan completarse
    // fuera de orden y dejar una versión anterior en disco.
    _pendingSaves.add(Workspace(tasks: _tasks, lists: _lists, tags: _tags));
    _saveDrain ??= _drainSaves();
    return _saveDrain!;
  }

  Future<void> _drainSaves() async {
    try {
      while (_pendingSaves.isNotEmpty) {
        final snapshot = _pendingSaves.removeAt(0);
        await _persist(snapshot);
      }
    } finally {
      _saveDrain = null;
    }
  }

  Future<void> _persist(Workspace snapshot) async {
    try {
      await _repository.save(snapshot);
      if (_errorMessage != null) {
        _errorMessage = null;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudieron guardar los cambios.',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'No se pudieron guardar los cambios.';
      notifyListeners();
    }
  }
}

class _DeletedTask {
  const _DeletedTask({required this.task, required this.index});

  final Task task;
  final int index;
}
