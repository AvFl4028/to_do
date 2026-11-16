import 'package:material_ui/material_ui.dart';

import '../application/task_scope.dart';
import '../application/task_store.dart';
import '../domain/task.dart';
import '../domain/task_tag.dart';
import '../domain/task_view.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';
import 'widgets/task_empty_state.dart';
import 'widgets/task_filter_bar.dart';
import 'widgets/task_tile.dart';

/// Contenido principal de la aplicación, sin `Scaffold`: el shell responsive
/// ([TasksHomePage]) aporta la AppBar, el drawer y el botón de nueva tarea.
class TaskListContent extends StatelessWidget {
  const TaskListContent({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final tasks = store.visibleTasks;
    final tags = store.tags;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            if (store.supportsStatusFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TaskFilterBar(
                  selected: store.filter,
                  counts: store.filterCounts,
                  onSelected: store.setFilter,
                ),
              ),
            if (store.errorMessage != null)
              _ErrorBanner(
                message: store.errorMessage!,
                onDismiss: store.clearError,
              ),
            Expanded(child: _buildContent(context, store, tasks, tags)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TaskStore store,
    List<Task> tasks,
    List<TaskTag> tags,
  ) {
    if (store.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return TaskEmptyState(
        view: store.view,
        filter: store.filter,
        onCreate: onCreate,
      );
    }

    final showList = store.view is! ListTasksView;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final list = store.listById(task.listId);
        final taskTags = <TaskTag>[
          for (final tag in tags)
            if (task.tagIds.contains(tag.id)) tag,
        ];

        return Dismissible(
          key: ValueKey<String>(task.id),
          direction: DismissDirection.endToStart,
          background: _DismissBackground(),
          onDismissed: (_) => _deleteTask(context, store, task),
          child: TaskTile(
            task: task,
            tags: taskTags,
            listLabel: showList && list != null
                ? (list.emoji, list.name)
                : null,
            onOpen: () => _openTask(context, task),
            onToggle: () => store.toggleCompleted(task.id),
            onToggleImportant: () => store.toggleImportant(task.id),
            onEdit: () => _editTask(context, store, task),
            onDelete: () => _deleteTask(context, store, task),
          ),
        );
      },
    );
  }

  void _openTask(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailPage(taskId: task.id),
      ),
    );
  }

  Future<void> _editTask(
    BuildContext context,
    TaskStore store,
    Task task,
  ) async {
    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute<TaskFormResult>(
        builder: (context) => TaskFormPage(task: task),
      ),
    );
    if (result == null) {
      return;
    }
    await store.updateTask(
      task.id,
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      listId: result.listId,
      isImportant: result.isImportant,
      tagIds: result.tagIds,
      attachments: result.attachments,
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    TaskStore store,
    Task task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await store.delete(task.id);
    if (!context.mounted) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('«${task.title}» eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => store.undoDelete(),
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.error_outline, color: scheme.onErrorContainer),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar aviso',
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
