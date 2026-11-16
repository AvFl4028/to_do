import 'package:to_do/features/tasks/data/workspace_repository.dart';
import 'package:to_do/features/tasks/domain/task.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/domain/task_tag.dart';
import 'package:to_do/features/tasks/domain/workspace.dart';

class InMemoryWorkspaceRepository implements WorkspaceRepository {
  InMemoryWorkspaceRepository({
    Workspace? initial,
    this.failOnLoad = false,
    this.failOnSave = false,
  }) : stored = initial ?? Workspace.empty();

  Workspace stored;
  bool failOnLoad;
  bool failOnSave;
  int saveCalls = 0;

  void seed({
    List<Task> tasks = const <Task>[],
    List<TaskList> lists = const <TaskList>[],
    List<TaskTag> tags = const <TaskTag>[],
  }) {
    stored = Workspace(tasks: tasks, lists: lists, tags: tags);
  }

  @override
  Future<Workspace> load() async {
    if (failOnLoad) {
      throw StateError('Fallo simulado de lectura.');
    }
    return stored;
  }

  @override
  Future<void> save(Workspace workspace) async {
    if (failOnSave) {
      throw StateError('Fallo simulado de escritura.');
    }
    saveCalls++;
    stored = workspace;
  }
}
