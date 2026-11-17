import 'package:material_ui/material_ui.dart';

import '../application/task_scope.dart';
import '../application/task_store.dart';
import '../domain/task.dart';
import '../domain/task_filter.dart';
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
    final completedInView = store.completedInView;

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
            if (completedInView.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey<String>('delete-completed-button'),
                    onPressed: () => _deleteCompleted(context, store),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: Text(
                      'Borrar completadas (${completedInView.length})',
                    ),
                  ),
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
    final grouped =
        store.supportsStatusFilter && store.filter == TaskFilter.all;
    final entries = grouped
        ? _groupedEntries(tasks)
        : <_RowEntry>[for (final task in tasks) _TaskEntry(task)];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          _SectionEntry(:final label, :final count) => _SectionHeader(
            key: ValueKey<String>('section-$label'),
            label: label,
            count: count,
          ),
          _DividerEntry() => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _TaskEntry(:final task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTaskTile(context, store, tags, showList, task),
          ),
        };
      },
    );
  }

  /// Divide las tareas visibles en pendientes y completadas. El orden interno
  /// de cada grupo se conserva tal como lo devuelve el store.
  List<_RowEntry> _groupedEntries(List<Task> tasks) {
    final pending = <Task>[];
    final completed = <Task>[];
    for (final task in tasks) {
      (task.isCompleted ? completed : pending).add(task);
    }

    return <_RowEntry>[
      if (pending.isNotEmpty) _SectionEntry('Pendientes', pending.length),
      for (final task in pending) _TaskEntry(task),
      if (pending.isNotEmpty && completed.isNotEmpty) const _DividerEntry(),
      if (completed.isNotEmpty) _SectionEntry('Completadas', completed.length),
      for (final task in completed) _TaskEntry(task),
    ];
  }

  Widget _buildTaskTile(
    BuildContext context,
    TaskStore store,
    List<TaskTag> tags,
    bool showList,
    Task task,
  ) {
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
        listLabel: showList && list != null ? (list.emoji, list.name) : null,
        onOpen: () => _openTask(context, task),
        onToggle: () => store.toggleCompleted(task.id),
        onToggleImportant: () => store.toggleImportant(task.id),
        onEdit: () => _editTask(context, store, task),
        onDelete: () => _deleteTask(context, store, task),
      ),
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

  Future<void> _deleteCompleted(BuildContext context, TaskStore store) async {
    final completed = store.completedInView;
    if (completed.isEmpty) {
      return;
    }

    final storage = TaskScope.attachmentsOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final count = completed.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar completadas'),
        content: Text(
          count == 1
              ? 'Se eliminará 1 tarea completada. Se borrarán las copias de '
                    'sus adjuntos; los archivos originales no se tocan.'
              : 'Se eliminarán $count tareas completadas. Se borrarán las '
                    'copias de sus adjuntos; los archivos originales no se tocan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final removed = await store.deleteCompletedInView();
    if (removed.isEmpty) {
      return;
    }

    // Solo se borran las copias internas que ya no referencia ninguna tarea.
    final remaining = store.storedAttachmentNames;
    final copies = <String>{
      for (final task in removed)
        for (final attachment in task.attachments)
          if (!remaining.contains(attachment.storedName)) attachment.storedName,
    };
    if (copies.isNotEmpty) {
      await storage.deleteStored(copies);
    }

    if (!messenger.mounted) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            removed.length == 1
                ? 'Se eliminó 1 tarea completada'
                : 'Se eliminaron ${removed.length} tareas completadas',
          ),
        ),
      );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Text(
        '$label ($count)',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

sealed class _RowEntry {
  const _RowEntry();
}

final class _SectionEntry extends _RowEntry {
  const _SectionEntry(this.label, this.count);

  final String label;
  final int count;
}

final class _TaskEntry extends _RowEntry {
  const _TaskEntry(this.task);

  final Task task;
}

final class _DividerEntry extends _RowEntry {
  const _DividerEntry();
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
